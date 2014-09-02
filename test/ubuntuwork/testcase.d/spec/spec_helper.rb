require 'serverspec'

include SpecInfra::Helper::Exec
include SpecInfra::Helper::DetectOS
include SpecInfra::Helper::Properties

properties      = {
	:wire_executable => '/mnt/project/bin/wire',
	:model_path 	 => '/mnt/project/test/d1'
}

RSpec.configure do |c|
  c.color = true
  c.tty = true
  set_property(properties)
  if ENV['ASK_SUDO_PASSWORD']
    require 'highline/import'
    c.sudo_password = ask("Enter sudo password: ") { |q| q.echo = false }
  else
    c.sudo_password = ENV['SUDO_PASSWORD']
  end
end
