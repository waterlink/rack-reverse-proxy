module RackReverseProxy
  # FIXME: Enable them and fix issues during refactoring
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize

  # Rule understands which urls need to be proxied
  class Rule
    def initialize(matcher, url = nil, options = {})
      @default_url = url
      @url = url
      @options = options

      if matcher.is_a?(String)
        @matcher = /^#{matcher}/
      elsif matcher.respond_to?(:match)
        @matcher = matcher
      else
        fail ArgumentError, "Invalid Rule for reverse_proxy"
      end
    end

    attr_reader :matcher, :url, :default_url, :options

    def proxy?(path, *args)
      match_path(path, *args) ? true : false
    end

    def get_uri(path, env)
      return nil if url.nil?
      realized_url = (url.respond_to?(:call) ? url.call(env) : url.clone)
      if realized_url =~ /\$\d/
        match_path(path).to_a.each_with_index { |m, i| realized_url.gsub!("$#{i}", m) }
        URI(realized_url)
      else
        default_url.nil? ? URI.parse(realized_url) : URI.join(realized_url, path)
      end
    end

    def to_s
      %("#{matcher}" => "#{url}")
    end

    private

    def match_path(path, *args)
      headers = args[0]
      rackreq = args[1]
      arity = matcher.method(:match).arity
      if arity == -1
        match = matcher.match(path)
      else
        params = [path, (@options[:accept_headers] ? headers : nil), rackreq]
        match = matcher.match(*params[0..(arity - 1)])
      end
      @url = match.url(path) if match && default_url.nil?
      match
    end
  end
end
