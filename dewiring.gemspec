lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'wire/version'

Gem::Specification.new do |s|
  s.name        = 'dewiring'
  s.platform    = Gem::Platform::RUBY
  s.version     = Wire::WireVersion::VERSION
  s.date        = '2014-09-02'
  s.summary     = 'Wire command line tool'
  s.description = 'System and Network architecture generator'
  s.authors     = ['Andreas Schmidt', 'Dustin Huptas']
  s.email       = 'gem@de-wiring.net'
  s.executables << 'wire'
  s.homepage    = 'https://github.com/de-wiring/wire'
  s.license     = 'MIT'

  s.required_ruby_version     = '>= 1.9.3'

  s.add_dependency 'thor', '>= 0.19.1'
  s.add_dependency 'rainbow', '>= 2.0.0'

  root_path      = File.dirname(__FILE__)
  s.require_path = 'lib'
  s.files        = Dir.chdir(root_path) { Dir.glob('lib/**/*') }
end
