# frozen_string_literal: true

source "https://rubygems.org"

gemspec

group :test do
  gem "base64"
  gem "cgi"
  gem "rack-test"
  gem "rspec"
  gem "rubocop"
  gem "webmock"
end

group :development, :test do
  gem "debug", :platforms => %i[mri windows]
  gem "simplecov"
end
