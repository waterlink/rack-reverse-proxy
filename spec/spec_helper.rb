# Code coverage
require "simplecov"
SimpleCov.start

require "rack/reverse_proxy"
require "rack/test"
require "webmock/rspec"

# Patch HttpStreamingResponse to make rack-proxy compatible with webmocks
require "support/http_streaming_response_patch"

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    # This option will default to `true` in RSpec 4.
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
    expectations.syntax = [:should, :expect]
  end
  config.mock_with :rspec do |mocks|
    mocks.verify_doubled_constant_names = true
    mocks.verify_partial_doubles = true
    mocks.syntax = [:should, :expect]
    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended, and will default to
    # `true` in RSpec 4.
    mocks.verify_partial_doubles = true
  end

  WebMock.disable_net_connect!
end
