# encoding: utf-8

include Wire::Execution

# Wire module
module Wire
  # Resource module
  module Resource
    # Generic IP Address on an interface
    class IPAddressOnIntf < ResourceBase
      attr_accessor	:device, :executables

      # initialize the object with
      # given name and device
      # params:
      # - name	ip address in cidr notation
      # - device device/interface name
      def initialize(name, device)
        super(name)

        @device = device
        @executables = {
          :ip => '/sbin/ip'
        }
      end

      def construct_exist_command
        "#{@executables[:ip]} addr show #{device} | grep -wq -E \"^\\W*inet #{@name}.*#{@device}\""
      end

      def exist?
        LocalExecution.with(construct_exist_command, [],
                            { :b_shell => false, :b_sudo => false }) do |exec_obj|
          exec_obj.run
          return (exec_obj.exitstatus == 0)
        end
      end

      def up?
        exist?
      end

      def up
      end

      def down?
        !(up?)
      end

      def down
      end

      def to_s
        "IPAddressOnIntf:[#{name},device=#{device}]"
      end
    end
  end
end
