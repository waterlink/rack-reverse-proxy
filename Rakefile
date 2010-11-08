require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "rack-reverse-proxy"
    gem.summary = %Q{A Simple Reverse Proxy for Rack}
    gem.description = %Q{A Rack based reverse proxy for basic needs.  Useful for testing or in cases where webserver configuration is unavailable.}
    gem.email = "jaswope@gmail.com"
    gem.homepage = "http://github.com/jaswope/rack-reverse-proxy"
    gem.authors = ["Jon Swope"]
    gem.add_development_dependency "rspec", ">= 0"
    gem.add_development_dependency "rack-test", ">= 0"
    gem.add_development_dependency "webmock", "~> 1.5.0"
    gem.add_dependency "rack", ">= 1.0.0"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => :check_dependencies

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "rack-reverse-proxy #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
