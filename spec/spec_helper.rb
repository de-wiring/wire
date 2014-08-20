require 'rubygems'

require 'simplecov'
SimpleCov.root './lib'
SimpleCov.coverage_dir '../coverage'
SimpleCov.start 

require 'bundler/setup'

require 'wire/common'
require 'wire/cli'
require 'wire/commands'
require 'wire/model'
require 'wire/execution'
require 'wire/resource'

include Wire


$log = Logger.new STDOUT
# parametrize
$log.formatter = proc do |severity, _, _, msg|
  "#{severity}  #{msg}\n"
end
$log.level = Logger::FATAL

# swap stdout/err by replacements
# => out/err replacement StringIO
def streams_before
  out_ = $stdout
  err_ = $stderr
  $stdout = StringIO.new
  $stderr = StringIO.new
  return out_,err_
end

# set back stdout to +out_+, stderr to +err_+
def streams_after(out_,err_)
  $stdout = out_
  $stderr = err_
end

RSpec.configure do |config|
	  config.mock_framework = :rspec
end
