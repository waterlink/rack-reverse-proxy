module RackReverseProxy
  # Rule understands which urls need to be proxied
  class Rule
    # FIXME: It needs to be hidden
    attr_reader :options

    def initialize(spec, url = nil, options = {})
      @custom_url = url.nil?
      @url = url
      @options = options
      @spec = build_matcher(spec)
    end

    def proxy?(path, *args)
      _matches(path, *args).count > 0
    end

    def get_uri(path, env)
      Candidate.new(self, url, custom_url, path, env).build_uri
    end

    def to_s
      %("#{spec}" => "#{url}")
    end

    # @private
    def _matches(path, *args)
      headers = args[0]
      rackreq = args[1]
      arity = spec.method(:match).arity
      if arity == -1
        match = spec.match(path)
      else
        params = [path, (@options[:accept_headers] ? headers : nil), rackreq]
        match = spec.match(*params[0..(arity - 1)])
      end
      # FIXME: This state mutation is very confusing
      @url = match.url(path) if match && custom_url
      Array(match)
    end

    private

    attr_reader :spec, :url, :custom_url

    def build_matcher(spec)
      return /^#{spec}/ if spec.is_a?(String)
      return spec if spec.respond_to?(:match)
      fail ArgumentError, "Invalid Rule for reverse_proxy"
    end

    # Candidate represents a request being matched
    class Candidate
      def initialize(rule, url, custom_url, path, env)
        @rule = rule
        @env = env
        @path = path
        @custom_url = custom_url

        @url = evaluate(url)
      end

      def build_uri
        return nil unless url
        URI(raw_uri)
      end

      private

      attr_reader :rule, :url, :custom_url, :path, :env

      def raw_uri
        return substitute_matches if with_substitutions?
        return just_uri if custom_url
        uri_with_path
      end

      def just_uri
        URI.parse(url)
      end

      def uri_with_path
        URI.join(url, path)
      end

      def evaluate(url)
        return unless url
        return url.call(env) if lazy?(url)
        url.clone
      end

      def lazy?(url)
        url.respond_to?(:call)
      end

      def with_substitutions?
        url =~ /\$\d/
      end

      def substitute_matches
        matches.each_with_index.inject(url) do |url, (match, i)|
          url.gsub("$#{i}", match)
        end
      end

      def matches
        rule._matches(path)
      end
    end
  end
end
