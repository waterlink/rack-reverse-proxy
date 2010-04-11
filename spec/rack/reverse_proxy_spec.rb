require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Rack::ReverseProxy do
  include Rack::Test::Methods
  include WebMock

  def app
    Rack::ReverseProxy.new
  end

  def dummy_app
    lambda { [200, {}, ['Dummy App']] }
  end

  describe "as middleware" do
    def app
      Rack::ReverseProxy.new(dummy_app) do
        reverse_proxy '/test', 'http://example.com/'
      end
    end

    it "should forward requests to the calling app when the path is not matched" do
      get '/'
      last_response.body.should == "Dummy App"
      last_response.should be_ok
    end

    it "should proxy requests when a pattern is matched" do
      stub_request(:get, 'http://example.com/test').to_return({:body => "Proxied App"})
      get '/test'
      last_response.body.should == "Proxied App"
    end

    describe "with ambiguous routes" do
      def app
        Rack::ReverseProxy.new(dummy_app) do
          reverse_proxy '/test', 'http://example.com/'
          reverse_proxy /^\/test/, 'http://example.com/'
        end
      end

      it "should throw an exception" do
        lambda { get '/test' }.should raise_error(Rack::AmbiguousProxyMatch)
      end
    end

    describe "with a route as a regular expression" do
      def app
        Rack::ReverseProxy.new(dummy_app) do
          reverse_proxy %r|^/test(/.*)$|, 'http://example.com$1'
        end
      end

      it "should support subcaptures" do
        stub_request(:get, 'http://example.com/path').to_return({:body => "Proxied App"})
        get '/test/path'
        last_response.body.should == "Proxied App"
      end
    end

    describe "with a matching route" do
      def app
        Rack::ReverseProxy.new(dummy_app) do
          reverse_proxy '/test', 'http://example.com/'
        end
      end

      %w|get head delete put post|.each do |method|
        describe "and using method #{method}" do
          it "should forward the correct request" do
            stub_request(method.to_sym, 'http://example.com/test').to_return({:body => "Proxied App for #{method}"})
            eval "#{method} '/test'"
            last_response.body.should == "Proxied App for #{method}"
          end

          if %w|put post|.include?(method)
            it "should forward the request payload" do
              pending "valid test with next release of WebMock" do
                stub_request(method.to_sym, 'http://example.com/test').to_return { |req| {:body => req.body} }
                eval "#{method} '/test', {:test => 'test'}"
                last_response.body.should == "test=test"
              end
            end
          end
        end
      end
    end
  end

  describe "as a rack app" do
    it "should respond with 404 when the path is not matched" do
      get '/'
      last_response.should be_not_found
    end
  end

end
