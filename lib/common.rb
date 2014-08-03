# encoding: utf-8

require 'thor'
require 'rainbow'

require 'yaml'
require 'pp'

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
