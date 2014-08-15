require 'rubygems'

require 'simplecov'
SimpleCov.start

require 'bundler/setup'

require 'common'
require 'cli'
require 'commands'
require 'model'
require 'execution'
require 'resource'

include Wire


$log = Logger.new STDOUT
# parametrize
$log.formatter = proc do |severity, _, _, msg|
  "#{severity}  #{msg}\n"
end
$log.level = Logger::FATAL

def streams_before
  out_ = $stdout
  err_ = $stderr
  $stdout = StringIO.new
  $stderr = StringIO.new
  return out_,err_
end

def streams_after(out_,err_)
  $stdout = out_
  $stderr = err_
end

RSpec.configure do |config|
	  config.mock_framework = :rspec
end
