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

      # vlanid (optional) and vlan trunk network
      attr_accessor :vlanid, :on_trunk

      # initialize the bridge object with
      # given +name+ and type
      # params:
      # - name	  bridge name, i.e. "br0"
      # - vlanid    optional vlanid, i.e. 100
      # - on_trunk  combine/optional with vlanid
      def initialize(name, vlanid = nil, on_trunk = nil)
        super(name)

        @vlanid = vlanid
        @on_trunk = on_trunk

        # TODO: make configurable
        @executables = {
          :vsctl => '/usr/bin/ovs-vsctl'
        }
      end

      # TODO: move to generic execution method
      # https://codeclimate.com/github/de-wiring/wire/Wire::Resource::OVSBridge
      # checks if the bridge exists
      # and - if vlan enabled - has right vlan settings (id, parent)
      def exist?
        b_exists = false
        LocalExecution.with(@executables[:vsctl],
                            ['br-exists', @name]) do |exec_obj|
          exec_obj.run
          b_exists = (exec_obj.exitstatus != 2)
        end
        b_vlan_ok = true
        if @vlanid && @on_trunk
          b_vlanid_ok = false
          b_parent_ok = false
          LocalExecution.with(@executables[:vsctl],
                              ['br-to-vlan', @name]) do |exec_obj|
            exec_obj.run
            b_vlanid_ok = (exec_obj.stdout.chomp == @vlanid.to_s)
          end
          LocalExecution.with(@executables[:vsctl],
                              ['br-to-parent', @name]) do |exec_obj|
            exec_obj.run
            b_parent_ok = (exec_obj.stdout.chomp == @on_trunk)
          end

          b_vlan_ok = b_vlanid_ok && b_parent_ok
        end

        b_exists && b_vlan_ok
      end

      # checks if the bridge exists
      def up?
        exist?
      end

      # adds the bridge.
      def up
        if @vlanid && @on_trunk
          up_vlan
        else
          up_no_vlan
        end
      end

      # adds the bridge  (ovs-vsctl add-br)
      # with no vlan associated
      def up_no_vlan
        LocalExecution.with(@executables[:vsctl],
                            ['add-br', @name]) do |up_exec_obj|
          up_exec_obj.run
          return (up_exec_obj.exitstatus == 0)
        end
      end

      # adds the bridge  (ovs-vsctl add-br)
      # with vlan associated.
      def up_vlan
        LocalExecution.with(@executables[:vsctl],
                            ['add-br', @name, @on_trunk, @vlanid]) do |up_exec_obj|
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
        "Bridge:[#{name},type=#{type},vlan=#{@vlanid},trunk=#{@on_trunk}]"
      end
    end
  end
end
