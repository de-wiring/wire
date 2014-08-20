# encoding: utf-8

# The MIT License (MIT)
# Copyright (c) 2014 Andreas Schmidt, andreas@de-wiring.net
#

include Wire::Execution

# Wire module
module Wire
  # Resource module
  module Resource
    # Generic IP Address on an interface
    # Able to add and remove ips on interfaces
    class IPAddressOnIntf < ResourceBase
      # +device+  (bridge) device name, i.e. "eth1"
      # +executables+   array of paths to needed binaries
      attr_accessor	:device, :executables

      # initialize the object with
      # given name and device
      # params:
      # +name+	ip address in cidr notation
      # +device+ device/interface name
      def initialize(name, device)
        super(name)

        fail(ArgumentError, 'ip may not be empty') unless name && name.size > 0
        fail(ArgumentError, 'device may not be empty') unless device && device.size > 0

        @device = device
        @executables = {
          :ip => '/sbin/ip'
        }
      end

      # constructs an ip addr show / grep command to see if an
      # ip address is up on a device
      # returns
      # - command as [String]
      def construct_exist_command
        "#{@executables[:ip]} addr show #{device} | grep -wq -E \"^\\W*inet #{@name}.*#{@device}\""
      end

      # runs the "exist" command
      # returns
      # - [Boolean]: true: ip is on on device, false otherwise
      def exist?
        LocalExecution.with(construct_exist_command, [],
                            { :b_shell => false, :b_sudo => false }) do |exec_obj|
          exec_obj.run
          return (exec_obj.exitstatus == 0)
        end
      end

      # same as exist?
      def up?
        exist?
      end

      # constructs an ip addr add command to set up an ip
      # returns
      # - command as [String]
      def construct_add_command
        "#{@executables[:ip]} addr add #{name} dev #{device}"
      end

      # takes an ip up on given device
      # returns
      # - [Boolean]: true: ok, false otherwise
      def up
        LocalExecution.with(construct_add_command, [],
                            { :b_shell => false, :b_sudo => true }) do |exec_obj|
          exec_obj.run
          return (exec_obj.exitstatus == 0)
        end
      end

      # constructs an ip addr del command to delete an ip
      # returns
      # - command as [String]
      def construct_delete_command
        "#{@executables[:ip]} addr del #{name} dev #{device}"
      end

      # thats the opposite of up
      def down?
        !(up?)
      end

      # takes an ip down on given device
      # returns
      # - [Boolean]: true: ok, false otherwise
      def down
        LocalExecution.with(construct_delete_command, [],
                            { :b_shell => false, :b_sudo => true }) do |exec_obj|
          exec_obj.run
          return (exec_obj.exitstatus == 0)
        end
      end

      # generate a string representation
      def to_s
        "IPAddressOnIntf:[#{name},device=#{device}]"
      end
    end
  end
end
