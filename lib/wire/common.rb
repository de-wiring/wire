# encoding: utf-8

# The MIT License (MIT)
# Copyright (c) 2014 Andreas Schmidt, andreas@de-wiring.net
#

require 'thor'

require 'rainbow'
require 'rainbow/ext/string'

require 'yaml'
require 'pp'
require 'English'
require 'erb'
require 'tempfile'

# set up log object
require 'logger'

$log = Logger.new STDOUT
# parametrize
$log.formatter = proc do |severity, _, _, msg|
  "#{severity}  #{msg}\n"
end
$log.level = Logger::INFO

# define exit codes
module Wire
  # central place for exit codes, given by +id+
  # Params
  # +id+ i.e. :init_bad_input
  # Returns
  # exitcode as [int]
  def self.cli_exitcode(id)
    codes = {
      :init_bad_input	=> 10,
      :init_dir_error => 20
    }
    codes[id]
  end
end
