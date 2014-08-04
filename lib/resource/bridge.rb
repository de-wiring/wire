# encoding: utf-8

include Wire::Execution

# Wire module
module Wire
  # Resource module
  module Resource
    # Open vSwitch Bridge resource
    class OVSBridge < ResourceBase
      attr_accessor	:type

      # initialize the bridge object with
      # given name and type
      # params:
      # - name	bridge name, i.e. "br0"
      def initialize(name)
        super(name)
      end

      def exist?
        LocalExecution.with('ovs-vsctl',
                            ['br-exists', @name]) do |exec_obj|
          exec_obj.run
          return (exec_obj.exitstatus != 2)
        end
      end

      def up?
        exist?
      end

      def up
        LocalExecution.with('ovs-vsctl',
                            ['add-br', @name]) do |up_exec_obj|
          up_exec_obj.run
          return (up_exec_obj.exitstatus != 2)
        end
      end

      def to_s
        "Bridge:[#{name},type=#{type}]"
      end
    end
  end
end
