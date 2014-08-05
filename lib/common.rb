# encoding: utf-8

require 'thor'

require 'rainbow'
require 'rainbow/ext/string'

require 'yaml'
require 'pp'
require 'English'
require 'erb'

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
  def self.cli_exitcode(id)
    codes = {
      :init_bad_input	=> 10,
      :init_dir_error => 20
    }
    codes[id]
  end
end
