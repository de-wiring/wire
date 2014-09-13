# encoding: utf-8

# The MIT License (MIT)
# Copyright (c) 2014 Andreas Schmidt, andreas@de-wiring.net
#

include Wire::Execution

# Wire module
module Wire
  # Resource module
  module Resource
    # Open vSwitch Bridge resource
    class OVSBridge < ResourceBase
      # +type+ of bridge (here: ovs)
      # +executables+ [Hash] of binaries needed to control
      # the resource
      attr_accessor	:type, :executables

      # initialize the bridge object with
      # given +name+ and type
      # params:
      # - name	bridge name, i.e. "br0"
      def initialize(name)
        super(name)

        # TODO: make configurable
        @executables = {
          :vsctl => '/usr/bin/ovs-vsctl'
        }
      end

      # TODO: move to generic execution method
      # https://codeclimate.com/github/de-wiring/wire/Wire::Resource::OVSBridge
      # checks if the bridge exists
      def exist?
        LocalExecution.with(@executables[:vsctl],
                            ['br-exists', @name]) do |exec_obj|
          exec_obj.run
          return (exec_obj.exitstatus != 2)
        end
      end

      # checks if the bridge exists
      def up?
        exist?
      end

      # adds the bridge  (ovs-vsctl add-br)
      def up
        LocalExecution.with(@executables[:vsctl],
                            ['add-br', @name]) do |up_exec_obj|
          up_exec_obj.run
          return (up_exec_obj.exitstatus == 0)
        end
      end

      # checks if the bridge is down
      def down?
        !(up?)
      end

      # deletes the bridge (ovs-vsctl del-br)
      def down
        LocalExecution.with(@executables[:vsctl],
                            ['del-br', @name]) do |down_exec_obj|
          down_exec_obj.run
          return (down_exec_obj.exitstatus == 0)
        end
      end

      # Returns a string representation
      def to_s
        "Bridge:[#{name},type=#{type}]"
      end
    end
  end
end
