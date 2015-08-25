module RackReverseProxy
  # Rule understands which urls need to be proxied
  class Rule
    # FIXME: It needs to be hidden
    attr_reader :options

    def initialize(spec, url = nil, options = {})
      @default_url = url
      @url = url
      @options = options
      @spec = build_matcher(spec)
    end

    def proxy?(path, *args)
      match_path(path, *args).count > 0
    end

    # Lots of calls with passing path and env around
    # Sounds like a class to me, Candidate?
    def get_uri(path, env)
      return nil unless url
      evaluated_url = evaluate_url(env)
      if with_substitutions?(evaluated_url)
        substitute_matches(evaluated_url, path)
      else
        build_simple_url(evaluated_url, path)
      end
    end

    def to_s
      %("#{spec}" => "#{url}")
    end

    private

    attr_reader :spec, :url, :default_url

    def build_simple_url(url, path)
      return URI.parse(url) unless default_url
      URI.join(url, path)
    end

    def evaluate_url(env)
      return url.clone unless url.respond_to?(:call)
      url.call(env)
    end

    def with_substitutions?(url)
      url =~ /\$\d/
    end

    # FIXME: This function currently is stressful for GC
    def substitute_matches(url, path)
      match_path(path).each_with_index do |match, i|
        url = url.gsub("$#{i}", match)
      end
      URI(url)
    end

    def build_matcher(spec)
      return /^#{spec}/ if spec.is_a?(String)
      return spec if spec.respond_to?(:match)
      fail ArgumentError, "Invalid Rule for reverse_proxy"
    end

    def match_path(path, *args)
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
      @url = match.url(path) if match && default_url.nil?
      Array(match)
    end

    # Candidate represents a path being verified
    class Candidate
    end
  end
end
