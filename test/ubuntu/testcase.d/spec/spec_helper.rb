require 'serverspec'

include SpecInfra::Helper::Exec
include SpecInfra::Helper::DetectOS
include SpecInfra::Helper::Properties

properties      = {
	:wire_executable => 'wire',
	:model_path 	 => '/home/vagrant/test/d1'
}

RSpec.configure do |c|
  c.color = true
  c.tty = true
  set_property(properties)
  c.sudo_password = ENV['SUDO_PASSWORD']
end
