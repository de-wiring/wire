# encoding: utf-8

# The MIT License (MIT)
# Copyright (c) 2014 Andreas Schmidt, andreas@de-wiring.net
#

include Wire::Execution

# Wire module
module Wire
  # Resource module
  module Resource
    # Open vSwitch Port resource. Attaches
    # a port to a bridge
    class OVSPort < ResourceBase
      # +type+ of bridge (here: ovs)
      # +executables+ [Hash] of binaries needed to control
      # the resource
      attr_accessor	:type, :executables

      # name of bridge, where to attach port
      attr_accessor :on_bridge

      # initialize the port object with
      # given +name+ and target +bridge+
      # params:
      # - name	  port name, i.e. "eth0"
      # - bridge  bridge name, i.e. "br0"
      def initialize(name, bridge)
        super(name)

        @on_bridge = bridge

        # TODO: make configurable
        @executables = {
          :vsctl => '/usr/bin/ovs-vsctl'
        }
      end

      # TODO: move to generic execution method
      # https://codeclimate.com/github/de-wiring/wire/Wire::Resource::OVSBridge
      # checks if the port exists and is connected to bridge
      def exist?
        b_exists = false
        LocalExecution.with(@executables[:vsctl],
                            ['port-to-br', @name, '2>/dev/null']) do |exec_obj|
          exec_obj.run
          b_exists = (exec_obj.stdout.chomp == @on_bridge.to_s)
        end
        b_exists
      end

      # checks if the port exists
      def up?
        exist?
      end

      # adds the port, attaches it to bridge.
      def up
        LocalExecution.with(@executables[:vsctl],
                            ['add-port', @on_bridge, @name]) do |up_exec_obj|
          up_exec_obj.run
          return (up_exec_obj.exitstatus == 0)
        end
      end

      # checks if the port is down
      def down?
        !(up?)
      end

      # deletes the port (ovs-vsctl del-port)
      def down
        LocalExecution.with(@executables[:vsctl],
                            ['del-port', @name]) do |down_exec_obj|
          down_exec_obj.run
          return (down_exec_obj.exitstatus == 0)
        end
      end

      # Returns a string representation
      def to_s
        "OVSPort:[#{name},type=#{type},on_bridge=#{@on_bridge}]"
      end
    end
  end
end
