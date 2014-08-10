# encoding: utf-8

include Wire::Execution

# Wire module
module Wire
  # Resource module
  module Resource
    # Open vSwitch Bridge resource
    class OVSBridge < ResourceBase
      attr_accessor	:type, :executables

      # initialize the bridge object with
      # given name and type
      # params:
      # - name	bridge name, i.e. "br0"
      def initialize(name)
        super(name)

        @executables = {
          :vsctl => '/usr/bin/ovs-vsctl'
        }
      end

      def exist?
        LocalExecution.with(@executables[:vsctl],
                            ['br-exists', @name]) do |exec_obj|
          exec_obj.run
          return (exec_obj.exitstatus != 2)
        end
      end

      def up?
        exist?
      end

      def up
        LocalExecution.with(@executables[:vsctl],
                            ['add-br', @name]) do |up_exec_obj|
          up_exec_obj.run
          return (up_exec_obj.exitstatus == 0)
        end
      end

      def down?
        !(up?)
      end

      def down
        LocalExecution.with(@executables[:vsctl],
                            ['del-br', @name]) do |down_exec_obj|
          down_exec_obj.run
          return (down_exec_obj.exitstatus == 0)
        end
      end

      def to_s
        "Bridge:[#{name},type=#{type}]"
      end
    end
  end
end
