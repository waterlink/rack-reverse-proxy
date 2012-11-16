require 'net/http'
require 'net/https'
require "net_http_hacked"
require "rack/http_streaming_response"

module Rack
  class ReverseProxy
    include NewRelic::Agent::Instrumentation::ControllerInstrumentation if defined? NewRelic

    def initialize(app = nil, &b)
      @app = app || lambda {|env| [404, [], []] }
      @matchers = []
      @global_options = {:preserve_host => true, :x_forwarded_host => true, :matching => :all, :verify_ssl => true}
      instance_eval &b if block_given?
    end

    def call(env)
      rackreq = Rack::Request.new(env)
      matcher = get_matcher rackreq.fullpath
      return @app.call(env) if matcher.nil?

      # if @global_options[:newrelic_instrumentation]
      #   action_name = "#{rackreq.path.gsub(/\/\d+/,'/:id').gsub(/^\//,'')}/#{rackreq.request_method}" # Rack::ReverseProxy/foo/bar#GET
      #   perform_action_with_newrelic_trace(:name => action_name, :request => rackreq) do
      #     perform_request(env, rackreq, matcher)
      #   end
      # else
        perform_request(env, rackreq, matcher)
      # end
    end

    private

    def perform_request(env, source_request, matcher)
      uri = matcher.get_uri(source_request.fullpath,env)
      
      # Initialize request
      target_request = Net::HTTP.const_get(source_request.request_method.capitalize).new(source_request.fullpath)

      # Setup headers
      target_request.initialize_http_header(extract_http_request_headers(source_request.env))

      # Setup body
      if target_request.request_body_permitted? && source_request.body
        source_request.body.rewind
        target_request.body_stream    = source_request.body
        target_request.content_length = source_request.content_length
        target_request.content_type   = source_request.content_type if source_request.content_type
      end
      
      # Create a streaming response (the actual network communication is deferred, a.k.a. streamed)
      target_response = HttpStreamingResponse.new(target_request, uri.host, uri.port)

      target_response.use_ssl = "https" == uri.scheme
      [target_response.status, target_response.headers, target_response.body]
    end

    def extract_http_request_headers(env)
      headers = env.reject do |k, v|
        !(/^HTTP_[A-Z_]+$/ === k) || v.nil?
      end.map do |k, v|
        [reconstruct_header_name(k), v]
      end.inject(Utils::HeaderHash.new) do |hash, k_v|
        k, v = k_v
        hash[k] = v
        hash
      end

      x_forwarded_for = (headers["X-Forwarded-For"].to_s.split(/, +/) << env["REMOTE_ADDR"]).join(", ")

      headers.merge!("X-Forwarded-For" =>  x_forwarded_for)
    end

    def reconstruct_header_name(name)
      name.sub(/^HTTP_/, "").gsub("_", "-")
    end




    def get_matcher path
      matches = @matchers.select do |matcher|
        matcher.match?(path)
      end

      if matches.length < 1
        nil
      elsif matches.length > 1 && @global_options[:matching] != :first
        raise AmbiguousProxyMatch.new(path, matches)
      else
        matches.first
      end
    end

    def create_response_headers http_response
      response_headers = Rack::Utils::HeaderHash.new(http_response)
      # handled by Rack
      response_headers.delete('status')
      # TODO: figure out how to handle chunked responses
      response_headers.delete('transfer-encoding')
      # TODO: Verify Content Length, and required Rack headers
      response_headers
    end


    def reverse_proxy_options(options)
      @global_options=options
    end

    def reverse_proxy matcher, url=nil, opts={}
      raise GenericProxyURI.new(url) if matcher.is_a?(String) && url.is_a?(String) && URI(url).class == URI::Generic
      @matchers << ReverseProxyMatcher.new(matcher,url,opts)
    end
  end

  class GenericProxyURI < Exception
    attr_reader :url

    def intialize(url)
      @url = url
    end

    def to_s
      %Q(Your URL "#{@url}" is too generic. Did you mean "http://#{@url}"?)
    end
  end

  class AmbiguousProxyMatch < Exception
    attr_reader :path, :matches
    def initialize(path, matches)
      @path = path
      @matches = matches
    end

    def to_s
      %Q(Path "#{path}" matched multiple endpoints: #{formatted_matches})
    end

    private

    def formatted_matches
      matches.map {|matcher| matcher.to_s}.join(', ')
    end
  end

  class ReverseProxyMatcher
    def initialize(matcher,url=nil,options)
      @url=url
      @options=options

      if matcher.kind_of?(String)
        @matcher = /^#{matcher.to_s}/
      elsif matcher.respond_to?(:match)
        @matcher = matcher
      else
        raise "Invalid Matcher for reverse_proxy"
      end
    end

    attr_reader :matcher,:url,:options

    def match?(path)
      match_path(path) ? true : false
    end

    def get_uri(path,env)
      _url=(url.respond_to?(:call) ? url.call(env) : url.clone)
      if _url =~/\$\d/
        match_path(path).to_a.each_with_index { |m, i| _url.gsub!("$#{i.to_s}", m) }
        URI(_url)
      else
        _url.include?(path) ? URI.parse(_url) : URI.join(_url, path)
      end
    end
    
    def to_s
      %Q("#{matcher.to_s}" => "#{url}")
    end

    private
    def match_path(path)
      match = matcher.match(path)
      @url = match.url(path) if match && url.nil?
      match
    end
  end
end
