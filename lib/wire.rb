# encoding: utf-8

require 'rubygems'

#
# modules
#
require_relative 'common.rb'
require_relative 'cli.rb'
require_relative 'commands.rb'
require_relative 'model.rb'
require_relative 'execution.rb'

include Wire

#
# main, drop into cli processing
#
WireCLI.start(ARGV)
