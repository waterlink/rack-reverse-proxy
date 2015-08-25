require "net/http"
require "net/https"
require "rack-proxy"

module RackReverseProxy
  # FIXME: Enable them and fix issues during refactoring
  # rubocop:disable Metrics/ClassLength
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  # rubocop:disable Metrics/AbcSize

  # Rack middleware for handling reverse proxying
  class Middleware
    include NewRelic::Agent::Instrumentation::ControllerInstrumentation if defined? NewRelic

    def initialize(app = nil, &b)
      @app = app || lambda { |_| [404, [], []] }
      @rules = []
      @global_options = {
        :preserve_host => true,
        :x_forwarded_host => true,
        :matching => :all,
        :replace_response_host => false
      }
      instance_eval(&b) if block_given?
    end

    def call(env)
      rackreq = Rack::Request.new(env)
      rule = get_rule(
        rackreq.fullpath,
        Rack::Proxy.extract_http_request_headers(rackreq.env),
        rackreq
      )
      return @app.call(env) if rule.nil?

      if @global_options[:newrelic_instrumentation]
        # Rack::ReverseProxy/foo/bar#GET
        action_path = rackreq.path.gsub(%r{/\d+}, "/:id").gsub(%r{^/}, "")
        action_name = "#{action_path}/#{rackreq.request_method}"
        perform_action_with_newrelic_trace(:name => action_name, :request => rackreq) do
          proxy(env, rackreq, rule)
        end
      else
        proxy(env, rackreq, rule)
      end
    end

    private

    def proxy(env, source_request, rule)
      uri = rule.get_uri(source_request.fullpath, env)
      return @app.call(env) if uri.nil?

      options = @global_options.dup.merge(rule.options)

      # Initialize request
      target_request = Net::HTTP.const_get(
        source_request.request_method.capitalize
      ).new(uri.request_uri)

      # Setup headers
      target_request_headers = Rack::Proxy.extract_http_request_headers(source_request.env)

      if options[:preserve_host]
        if uri.port == uri.default_port
          target_request_headers["HOST"] = uri.host
        else
          target_request_headers["HOST"] = "#{uri.host}:#{uri.port}"
        end
      end

      if options[:x_forwarded_host]
        target_request_headers["X-Forwarded-Host"] = source_request.host
        target_request_headers["X-Forwarded-Port"] = "#{source_request.port}"
      end

      target_request.initialize_http_header(target_request_headers)

      # Basic auth
      if options[:username] && options[:password]
        target_request.basic_auth options[:username], options[:password]
      end

      # Setup body
      if target_request.request_body_permitted? && source_request.body
        source_request.body.rewind
        target_request.body_stream = source_request.body
      end

      target_request.content_length = source_request.content_length || 0
      target_request.content_type   = source_request.content_type if source_request.content_type

      # Create a streaming response (the actual network communication is deferred, a.k.a. streamed)
      target_response = Rack::HttpStreamingResponse.new(target_request, uri.host, uri.port)

      # pass the timeout configuration through
      target_response.read_timeout = options[:timeout] if options[:timeout].to_i > 0

      target_response.use_ssl = "https" == uri.scheme

      # Let rack set the transfer-encoding header
      response_headers = Rack::Utils::HeaderHash.new(
        Rack::Proxy.normalize_headers(format_headers(target_response.headers))
      )
      response_headers.delete("Transfer-Encoding")
      response_headers.delete("Status")

      # Replace the location header with the proxy domain
      if response_headers["Location"] && options[:replace_response_host]
        response_location = URI(response_headers["location"])
        response_location.host = source_request.host
        response_location.port = source_request.port
        response_headers["Location"] = response_location.to_s
      end

      [target_response.status, response_headers, target_response.body]
    end

    def get_rule(path, headers, rackreq)
      matches = @rules.select do |rule|
        rule.proxy?(path, headers, rackreq)
      end

      if matches.length < 1
        nil
      elsif matches.length > 1 && @global_options[:matching] != :first
        fail Errors::AmbiguousMatch.new(path, matches)
      else
        matches.first
      end
    end

    def reverse_proxy_options(options)
      @global_options = options
    end

    def reverse_proxy(rule, url = nil, opts = {})
      if rule.is_a?(String) && url.is_a?(String) && URI(url).class == URI::Generic
        fail Errors::GenericURI.new, url
      end
      @rules << Rule.new(rule, url, opts)
    end

    def format_headers(headers)
      headers.inject({}) do |acc, (key, val)|
        formated_key = key.split("-").map(&:capitalize).join("-")
        acc[formated_key] = Array(val)
        acc
      end
    end
  end
end
