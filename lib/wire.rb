# encoding: utf-8

require 'rubygems'

#
# modules
#
require_relative 'wire/common.rb'
require_relative 'wire/cli.rb'
require_relative 'wire/commands.rb'
require_relative 'wire/model.rb'
require_relative 'wire/execution.rb'
require_relative 'wire/resource.rb'

include Wire

#
# main, drop into cli processing
#
WireCLI.start(ARGV)
