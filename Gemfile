source "https://rubygems.org"

gemspec

RUBOCOP_PLATFORMS = [:ruby_20, :ruby_21, :ruby_22]

ruby_version = RUBY_VERSION.to_f
if ruby_version < 2.0  # 1.9.3 and 1.8.7
  RUBOCOP_PLATFORMS = [:ruby_20, :ruby_21]
end

group :test do
  gem "rspec"
  gem "rack-test"
  gem "webmock"
  gem "rubocop", :platform => RUBOCOP_PLATFORMS

  if ruby_version < 1.9  # 1.8.7
    gem "addressable", "< 2.4"
  end
end

group :development, :test do
  gem "simplecov"
end
