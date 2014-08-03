require 'rubygems'
require 'bundler/setup'

require 'common'
require 'cli'
require 'commands'
require 'model'
require 'execution'

include Wire

RSpec.configure do |config|
	  config.mock_framework = :rspec
end
