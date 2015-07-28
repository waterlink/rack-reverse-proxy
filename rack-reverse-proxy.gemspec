Gem::Specification.new do |s|
  s.name          = 'rack-reverse-proxy'
  s.version       = "0.9.1"
  s.authors       = ["Jon Swope", "Ian Ehlert", "Roman Ernst", "Oleksii Fedorov"]
  s.description   = 'A Rack based reverse proxy for basic needs.  Useful for testing or in cases where webserver configuration is unavailable.'
  s.email         = ["jaswope@gmail.com", "ehlertij@gmail.com", "rernst@farbenmeer.net", "waterlink000@gmail.com"]
  s.files         = Dir['README.md', 'LICENSE', 'lib/**/*']
  s.homepage      = 'http://github.com/waterlink/rack-reverse-proxy'
  s.require_paths = ["lib"]
  s.summary       = 'A Simple Reverse Proxy for Rack'

  s.add_development_dependency "rake", "~> 10.3"
  s.add_development_dependency "guard-rspec"
  s.add_development_dependency "guard-bundler"

  s.add_dependency "rack", ">= 1.0.0"
  s.add_dependency "rack-proxy", "~> 0.5", ">= 0.5.14"
end
