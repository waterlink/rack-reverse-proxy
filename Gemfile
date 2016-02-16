source "https://rubygems.org"

gemspec

group :test do
  gem "rspec"
  gem "rack-test"
  gem "webmock"
  gem "rubocop", :platform => [:ruby_20, :ruby_21, :ruby_22]

  if RUBY_VERSION.to_f < 1.9
    gem "addressable", "< 2.4"
  end
end

group :development, :test do
  gem "simplecov"
end
