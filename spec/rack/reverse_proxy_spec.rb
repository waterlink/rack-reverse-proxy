require 'spec_helper'

RSpec.describe Rack::ReverseProxy do
  include Rack::Test::Methods

  def app
    Rack::ReverseProxy.new
  end

  def dummy_app
    lambda { |env| [200, {}, ['Dummy App']] }
  end

  describe "as middleware" do
    def app
      Rack::ReverseProxy.new(dummy_app) do
        reverse_proxy '/test', 'http://example.com/', {:preserve_host => true}
        reverse_proxy '/2test', lambda{ |env| 'http://example.com/'}
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

    it "should produce a response header of type HeaderHash" do
      stub_request(:get, 'http://example.com/test')
      get '/test'
      last_response.headers.should be_an_instance_of Rack::Utils::HeaderHash
    end

    it "should parse the headers as a Hash with values of type String" do
      stub_request(:get, 'http://example.com/test').to_return({:headers => {'cache-control'=> 'max-age=300, public'} })
      get '/test'
      last_response.headers['cache-control'].should be_an_instance_of String
      last_response.headers['cache-control'].should == 'max-age=300, public'
    end

    it "should proxy requests to a lambda url when a pattern is matched" do
      stub_request(:get, 'http://example.com/2test').to_return({:body => "Proxied App2"})
      get '/2test'
      last_response.body.should == "Proxied App2"
    end

    it "should set the Host header w/o default port" do
      stub_request(:any, 'example.com/test/stuff')
      get '/test/stuff'
      a_request(:get, 'http://example.com/test/stuff').with(:headers => {"Host" => "example.com"}).should have_been_made
    end

    it "should set the X-Forwarded-Host header to the proxying host by default" do
      stub_request(:any, 'example.com/test/stuff')
      get '/test/stuff'
      a_request(:get, 'http://example.com/test/stuff').with(:headers => {'X-Forwarded-Host' => 'example.org'}).should have_been_made
    end

    it 'should format the headers correctly to avoid duplicates' do
      stub_request(:get, 'http://example.com/2test').to_return({:status => 301, :headers => {:status => '301 Moved Permanently'}})

      get '/2test'

      headers = last_response.headers.to_hash
      headers['Status'].should == "301 Moved Permanently"
      headers['status'].should be_nil
    end

    it 'should format the headers with dashes correctly' do
      stub_request(:get, 'http://example.com/2test').to_return({:status => 301, :headers => {:status => '301 Moved Permanently', :"x-additional-info" => "something"}})

      get '/2test'

      headers = last_response.headers.to_hash
      headers['X-Additional-Info'].should == "something"
      headers['x-additional-info'].should be_nil
    end

    describe "with non-default port" do
      def app
        Rack::ReverseProxy.new(dummy_app) do
          reverse_proxy '/test', 'http://example.com:8080/'
        end
      end

      it "should set the Host header including non-default port" do
        stub_request(:any, 'example.com:8080/test/stuff')
        get '/test/stuff'
        a_request(:get, 'http://example.com:8080/test/stuff').with(:headers => {"Host" => "example.com:8080"}).should have_been_made
      end
    end

    describe "with preserve host turned off" do
      def app
        Rack::ReverseProxy.new(dummy_app) do
          reverse_proxy '/test', 'http://example.com/', {:preserve_host => false}
        end
      end

      it "should not set the Host header" do
        stub_request(:any, 'example.com/test/stuff')
        get '/test/stuff'
        a_request(:get, 'http://example.com/test/stuff').with(:headers => {"Host" => "example.com"}).should_not have_been_made
        a_request(:get, 'http://example.com/test/stuff').should have_been_made
      end
    end

    describe "with x_forwarded_host turned off" do
      def app
        Rack::ReverseProxy.new(dummy_app) do
          reverse_proxy_options :x_forwarded_host => false
          reverse_proxy '/test', 'http://example.com/'
        end
      end

      it "should not set the X-Forwarded-Host header to the proxying host" do
        stub_request(:any, 'example.com/test/stuff')
        get '/test/stuff'
        a_request(:get, 'http://example.com/test/stuff').with(:headers => {'X-Forwarded-Host' => 'example.org'}).should_not have_been_made
        a_request(:get, 'http://example.com/test/stuff').should have_been_made
      end
    end

    describe "with timeout configuration" do
      def app
        Rack::ReverseProxy.new(dummy_app) do
          reverse_proxy '/test/slow', 'http://example.com/', {:timeout => 99}
        end
      end

      it "should make request with basic auth" do
        stub_request(:get, "http://example.com/test/slow")
        Rack::HttpStreamingResponse.any_instance.should_receive(:set_read_timeout).with(99)
        get '/test/slow'
      end
    end

    describe "without timeout configuration" do
      def app
        Rack::ReverseProxy.new(dummy_app) do
          reverse_proxy '/test/slow', 'http://example.com/'
        end
      end

      it "should make request with basic auth" do
        stub_request(:get, "http://example.com/test/slow")
        Rack::HttpStreamingResponse.any_instance.should_not_receive(:set_read_timeout)
        get '/test/slow'
      end
    end

    describe "with basic auth turned on" do
      def app
        Rack::ReverseProxy.new(dummy_app) do
          reverse_proxy '/test', 'http://example.com/', {:username => "joe", :password => "shmoe"}
        end
      end

      it "should make request with basic auth" do
        stub_request(:get, "http://joe:shmoe@example.com/test/stuff").to_return(:body => "secured content")
        get '/test/stuff'
        last_response.body.should == "secured content"
      end
    end

    describe "with preserve response host turned on" do
      def app
        Rack::ReverseProxy.new(dummy_app) do
          reverse_proxy '/test', 'http://example.com/', {:replace_response_host => true}
        end
      end

      it "should replace the location response header" do
        stub_request(:get, "http://example.com/test/stuff").to_return(:headers => {"location" => "http://test.com/bar"})
        get 'http://example.com/test/stuff'
        last_response.headers['location'].should == "http://example.com/bar"
      end

      it "should keep the port of the location" do
        stub_request(:get, "http://example.com/test/stuff").to_return(:headers => {"location" => "http://test.com/bar"})
        get 'http://example.com:3000/test/stuff'
        last_response.headers['location'].should == "http://example.com:3000/bar"
      end
    end

    describe "with ambiguous routes and all matching" do
      def app
        Rack::ReverseProxy.new(dummy_app) do
          reverse_proxy_options :matching => :all
          reverse_proxy '/test', 'http://example.com/'
          reverse_proxy(/^\/test/, 'http://example.com/')
        end
      end

      it "should throw an exception" do
        lambda { get '/test' }.should raise_error(Rack::AmbiguousProxyMatch)
      end
    end

    describe "with ambiguous routes and first matching" do
      def app
        Rack::ReverseProxy.new(dummy_app) do
          reverse_proxy_options :matching => :first
          reverse_proxy '/test', 'http://example1.com/'
          reverse_proxy(/^\/test/, 'http://example2.com/')
        end
      end

      it "should throw an exception" do
        stub_request(:get, 'http://example1.com/test').to_return({:body => "Proxied App"})
        get '/test'
        last_response.body.should == "Proxied App"
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

    describe "with a https route" do
      def app
        Rack::ReverseProxy.new(dummy_app) do
          reverse_proxy '/test', 'https://example.com'
        end
      end

      it "should make a secure request" do
        stub_request(:get, 'https://example.com/test/stuff').to_return({:body => "Proxied Secure App"})
        get '/test/stuff'
        last_response.body.should == "Proxied Secure App"
      end

      it "should set the Host header w/o default port" do
        stub_request(:any, 'https://example.com/test/stuff')
        get '/test/stuff'
        a_request(:get, 'https://example.com/test/stuff').with(:headers => {"Host" => "example.com"}).should have_been_made
      end
    end

    describe "with a https route on non-default port" do
      def app
        Rack::ReverseProxy.new(dummy_app) do
          reverse_proxy '/test', 'https://example.com:8443'
        end
      end

      it "should set the Host header including non-default port" do
        stub_request(:any, 'https://example.com:8443/test/stuff')
        get '/test/stuff'
        a_request(:get, 'https://example.com:8443/test/stuff').with(:headers => {"Host" => "example.com:8443"}).should have_been_made
      end
    end

    describe "with a route as a string" do
      def app
        Rack::ReverseProxy.new(dummy_app) do
          reverse_proxy '/test', 'http://example.com'
          reverse_proxy '/path', 'http://example.com/foo$0'
        end
      end

      it "should append the full path to the uri" do
        stub_request(:get, 'http://example.com/test/stuff').to_return({:body => "Proxied App"})
        get '/test/stuff'
        last_response.body.should == "Proxied App"
      end

    end

    describe "with a generic url" do
      def app
        Rack::ReverseProxy.new(dummy_app) do
          reverse_proxy '/test', 'example.com'
        end
      end

      it "should throw an exception" do
        lambda{ app }.should raise_error(Rack::GenericProxyURI)
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
              stub_request(method.to_sym, 'http://example.com/test').to_return { |req| {:body => req.body} }
              eval "#{method} '/test', {:test => 'test'}"
              last_response.body.should == "test=test"
            end
          end
        end
      end
    end

    describe "with a matching class" do
      class Matcher
        def self.match(path)
          if path.match(/^\/(test|users)/)
            Matcher.new
          end
        end

        def url(path)
          if path.include?("user")
            'http://users-example.com' + path
          else
            'http://example.com' + path
          end
        end
      end

      def app
        Rack::ReverseProxy.new(dummy_app) do
          reverse_proxy Matcher
        end
      end

      it "should forward requests to the calling app when the path is not matched" do
        get '/'
        last_response.body.should == "Dummy App"
        last_response.should be_ok
      end

      it "should proxy requests when a pattern is matched" do
        stub_request(:get, 'http://example.com/test').to_return({:body => "Proxied App"})
        stub_request(:get, 'http://users-example.com/users').to_return({:body => "User App"})
        get '/test'
        last_response.body.should == "Proxied App"
        get '/users'
        last_response.body.should == "User App"
      end
    end

    describe "with a matching class" do
      class RequestMatcher
        attr_accessor :rackreq

        def initialize(rackreq)
          self.rackreq = rackreq
        end

        def self.match(path, headers, rackreq)
          if path.match(/^\/(test|users)/)
            RequestMatcher.new(rackreq)
          end
        end

        def url(path)
          if rackreq.params["user"] == 'omer'
            'http://users-example.com' + path
          end
        end
      end

      def app
        Rack::ReverseProxy.new(dummy_app) do
          reverse_proxy RequestMatcher
        end
      end

      it "should forward requests to the calling app when the path is not matched" do
        get '/'
        last_response.body.should == "Dummy App"
        last_response.should be_ok
      end

      it "should proxy requests when a pattern is matched" do
        stub_request(:get, 'http://users-example.com/users?user=omer').to_return({:body => "User App"})
        get '/test', :user => "mark"
        last_response.body.should == "Dummy App"
        get '/users', :user => 'omer'
        last_response.body.should == "User App"
      end
    end


    describe "with a matching class that accepts headers" do
      class MatcherHeaders
        def self.match(path, headers)
          if path.match(/^\/test/) && headers['ACCEPT'] && headers['ACCEPT'] == 'foo.bar'
            MatcherHeaders.new
          end
        end

        def url(path)
          'http://example.com' + path
        end
      end

      def app
        Rack::ReverseProxy.new(dummy_app) do
          reverse_proxy MatcherHeaders, nil, {:accept_headers => true}
        end
      end

      it "should proxy requests when a pattern is matched and correct headers are passed" do
        stub_request(:get, 'http://example.com/test').to_return({:body => "Proxied App with Headers"})
        get '/test', {}, {'HTTP_ACCEPT' => 'foo.bar'}
        last_response.body.should == "Proxied App with Headers"
      end

      it "should not proxy requests when a pattern is matched and incorrect headers are passed" do
        stub_request(:get, 'http://example.com/test').to_return({:body => "Proxied App with Headers"})
        get '/test', {}, {'HTTP_ACCEPT' => 'bar.foo'}
        last_response.body.should_not == "Proxied App with Headers"
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
