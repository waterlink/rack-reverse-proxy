require "rack-proxy"
module Rack
  # Overload rack-proxy HttpStreamingResponse#session to allow for more options
  class HttpStreamingResponse
    attr_accessor :timeout, :verify_ssl

    def session
      @session ||= begin
        http = Net::HTTP.new @host, @port
        http.use_ssl = self.use_ssl
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE if self.use_ssl && !self.verify_ssl.nil? && self.verify_ssl == false
        http.read_timeout = self.timeout unless self.timeout.nil?
        http.start
      end
    end
  end
end