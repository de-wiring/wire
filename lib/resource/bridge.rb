# encoding: utf-8

module Wire
	module Resource

		# Open vSwitch Bridge resource
		class OVSBridge < ResourceBase
			attr_accessor	:type

			# initialize the bridge object with
			# given name and type
			# params:
			# - name	bridge name, i.e. "br0"
			# - type	supported bridge types, i.e. :ovs
			def initialize(name,type)
				super.initialize(name)
				@type = type
			end

			def exist?
        exist_exec = LocalExecution.new('ovs-vsctl',['br-exists',@name])
        exist_exec.run

        return (exist_exec.exitstatus != 2)
			end

			def is_up?
			end

			def up
			end

			def to_s
				"Bridge:[#{name},type=#{type}]"
			end

		end

	end

end
