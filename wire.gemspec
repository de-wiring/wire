lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'wire/version'

Gem::Specification.new do |s|
  s.name        = 'wire'
  s.platform    = Gem::Platform::RUBY
  s.version     = Wire::WireVersion::VERSION
  s.date        = '2014-08-15'
  s.summary     = 'Wire command line tool'
  s.description = 'System and Network architecture generator'
  s.authors     = ['Andreas Schmidt', 'Dustin Huptas']
  s.email       = 'gem@de-wiring.net'
  s.executables << 'wire'
  s.homepage    = 'http://www.de-wiring.net'
  s.license     = 'MIT'

  s.required_ruby_version     = '>= 1.9.3'

  s.add_dependency 'thor', '>= 0.19.1'
  s.add_dependency 'rainbow', '>= 2.0.0'

  root_path      = File.dirname(__FILE__)
  s.require_path = 'lib'
  s.files        = Dir.chdir(root_path) { Dir.glob('lib/{*,.*}') }
end
