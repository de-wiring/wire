# encoding: utf-8

include Wire::Execution

# Wire module
module Wire
  # Resource module
  module Resource
    # Generic IP Address on an interface
    # Able to add and remove ips on interfaces
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

        fail(ArgumentError, 'ip may not be empty') unless name && name.size > 0
        fail(ArgumentError, 'device may not be empty') unless device && device.size > 0
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

      def construct_add_command
        "#{@executables[:ip]} addr add #{name} dev #{device}"
      end

      def up
        LocalExecution.with(construct_add_command, [],
                            { :b_shell => false, :b_sudo => true }) do |exec_obj|
          exec_obj.run
          return (exec_obj.exitstatus == 0)
        end
      end

      def construct_delete_command
        name32 = (name =~ /^[0-9\.]+\32$/) ? name : "#{name}/32"
        "#{@executables[:ip]} addr del #{name32} dev #{device}"
      end

      def down?
        !(up?)
      end

      def down
        LocalExecution.with(construct_delete_command, [],
                            { :b_shell => false, :b_sudo => true }) do |exec_obj|
          exec_obj.run
          return (exec_obj.exitstatus == 0)
        end
      end

      def to_s
        "IPAddressOnIntf:[#{name},device=#{device}]"
      end
    end
  end
end
