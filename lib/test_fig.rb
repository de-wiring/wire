# encoding: utf-8

# The MIT License (MIT)
# Copyright (c) 2014 Andreas Schmidt, andreas@de-wiring.net
#

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

$log.level = Logger::DEBUG

fa = Wire::Resource::FigAdapter.new('wiredmz', 'test/d1/fig/fig_dmz.yaml')
pp fa

$log.info 'Checking if containers are up'
r = fa.up?
$log.info "Result=#{r}"

$log.info 'Bringing it up...'
r = fa.up
$log.info "Result=#{r}"

$log.info 'Checking if containers are up'
r = fa.up?
$log.info "Result=#{r}"

$log.info "IDs=#{fa.up_ids}"

$log.info 'Taking it down...'
r = fa.down
$log.info "Result=#{r}"

$log.info 'Checking if containers are up'
r = fa.up?
$log.info "Result=#{r}"

