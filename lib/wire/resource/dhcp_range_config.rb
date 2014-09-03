# encoding: utf-8

# The MIT License (MIT)
# Copyright (c) 2014 Andreas Schmidt, andreas@de-wiring.net
#

include Wire::Execution

# Wire module
module Wire
  # Resource module
  module Resource
    # DHCPRangeConfiguration is a configuration resource
    # for dnsmasq to support dhcp for a given network range
    # on a given interface
    class DHCPRangeConfiguration < ResourceBase
      # +network_name+ name of network (and bridge)
      # +network+ network entry
      # +address_start+ start of address range (i.e.192.168.10.10)
      # +address_end+ end of dhcp address range (i.e.192.168.10.100)
      # +executables+ [Hash] of binaries needed to control
      # the resource
      attr_accessor	:address_start, :address_end, :network_name, :network, :executables

      # initialize the resourcen object with
      # given +name+ and attributes
      # params:
      # +name+	resource name
      # +network_name+ name of network (and bridge)
      # +network+ network entry
      # +address_start+ start of address range (i.e.192.168.10.10)
      # +address_end+ end of dhcp address range (i.e.192.168.10.100)
      def initialize(name, network_name, network, address_start, address_end)
        super(name)

        self.network_name = network_name
        self.network = network
        self.address_start = address_start
        self.address_end = address_end

        # TODO: make configurable
        @executables = {
          :service => '/usr/sbin/service'
        }
      end

      # Build file name of dnsmasq file
      # TODO: make configurable
      def create_dnsmaqs_config_filename
        "/etc/dnsmasq.d/#{@name}__#{@network_name}.conf"
      end

      # check if configuration entry exists
      def exist?
        filename = create_dnsmaqs_config_filename
        File.exist?(filename) && File.readable?(filename) && File.file?(filename)
      end

      # check if dnsmasq is listening on the network device
      def up?
        return false unless exist?

        filename = create_dnsmaqs_config_filename

        cmd = "/bin/grep #{network_name} #{filename} >/dev/null 2>&1"
        $log.debug("executing cmd=#{cmd}")
        `#{cmd}`

        ($CHILD_STATUS == 0)
      end

      # restart dnsmasq service
      def restart_dnsmasq
        $log.debug('Restarting dnsmasq')
        LocalExecution.with(@executables[:service],
                            %w(dnsmasq restart),
                            { :b_sudo => true, :b_shell => false }) do |up_exec_obj|
          up_exec_obj.run
          return (up_exec_obj.exitstatus == 0)
        end
      end

      # creates the configuration and restarts dnsmasq
      def up
        filename = create_dnsmaqs_config_filename

        # use sudo'ed touch/chmod to create us the file we need
        LocalExecution.with("sudo touch #{filename} && " \
                            "sudo chmod u+rw #{filename} && " \
                            "sudo chown #{ENV['USER']} #{filename}",
                            [], { :b_sudo => false, :b_shell => true }) do |up_exec_obj|
          up_exec_obj.run
        end
        $log.debug("(Over-)writing #{filename}")
        File.open(filename, 'w') do |file|
          # TODO: add netmask
          file.puts "dhcp-range=#{@network_name},#{@address_start},#{@address_end}"
        end

        restart_dnsmasq
      rescue => exception
        $log.error("Error writign dnsmasq config file/restarting dnsmasq, #{exception}")
        return false
      end

      # checks if dnsmasq is NOT servicing dhcp request on network device
      def down?
        !(up?)
      end

      # removes configuration entry and restarts dnsmasq
      def down
        filename = create_dnsmaqs_config_filename
        if File.exist?(filename) && File.readable?(filename) && File.file?(filename)
          $log.debug("Deleting #{filename}")
          LocalExecution.with("sudo rm #{filename}",
                              [], { :b_sudo => false, :b_shell => true }) do |up_exec_obj|
            up_exec_obj.run
          end

          restart_dnsmasq
        end
      rescue => exception
        $log.error("Error deleting dnsmasq config file/restarting dnsmasq, #{exception}")
        return false
      end

      # Returns a string representation
      def to_s
        "DHCPRangeConfiguration:[#{name},network_name=#{network[:name]}" \
        ",start=#{address_start},end=#{address_end}]"
      end
    end
  end
end
