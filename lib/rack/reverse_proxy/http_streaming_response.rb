module Rack
  class HttpStreamingResponse
    def set_read_timeout(value)
      self.read_timeout = value
    end
  end
end
