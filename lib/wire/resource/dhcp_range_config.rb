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

      def create_dnsmaqs_config_filename
        "/etc/dnsmasq.d/#{@name}.conf"
      end

      # check if configuration entry exists
      def exist?
        $log.debug('DHCPRangeConfiguration.exist?')
        filename = create_dnsmaqs_config_filename
        File.exist?(filename) && File.readable?(filename) && File.file?(filename)
      end

      # check if dnsmasq is listening on the network device
      def up?
        $log.debug('DHCPRangeConfiguration.up?')
        return false unless exist?

        filename = create_dnsmaqs_config_filename

        #cmd = "/bin/nc -uvzw2 #{network[:hostip]} 67 >/dev/null 2>&1"
        cmd = "/bin/grep #{network_name} #{filename} >/dev/null 2>&1"
        $log.debug("executing cmd=#{cmd}")
        `#{cmd}`

        ($? == 0)
      end

      # creates the configuration and restarts dnsmasq
      def up
        $log.debug('DHCPRangeConfiguration.up')
        begin
          filename = create_dnsmaqs_config_filename
          $log.debug("(Over-)writing #{filename}")
          open(filename,'w') do |f|
            # TODO: add netmask
            f.puts "dhcp-range=#{@network_name},#{@address_start},#{@address_end}"
          end

          $log.debug('Restarting dnsmasq')
          LocalExecution.with(@executables[:service],
                              ['dnsmasq', 'restart']) do |up_exec_obj|
            up_exec_obj.run
            return (up_exec_obj.exitstatus == 0)
          end
        rescue => e
          $log.error("Error writign dnsmasq config file/restarting dnsmasq, #{e}")
          return false
        end

      end

      # checks if dnsmasq is NOT service dhcp request on network device
      def down?
        $log.debug('DHCPRangeConfiguration.down?')
        false
      end

      # removes configuration entry and restarts dnsmasq
      def down
        $log.debug('DHCPRangeConfiguration.down')
        begin
          filename = create_dnsmaqs_config_filename
          if File.exist?(filename) && File.readable?(filename) && File.file?(filename)
            $log.debug("Deleting #{filename}")
            File.delete(filename)

            $log.debug('Restarting dnsmasq')
            LocalExecution.with(@executables[:service],
                                ['dnsmasq', 'restart']) do |up_exec_obj|
              up_exec_obj.run
              return (up_exec_obj.exitstatus == 0)
            end
          end
        rescue => e
          $log.error("Error deleting dnsmasq config file/restarting dnsmasq, #{e}")
          return false
        end
      end

      # Returns a string representation
      def to_s
        "DHCPRangeConfiguration:[#{name},network_name=#{network[:name]}" \
        ",start=#{address_start},end=#{address_end}]"
      end
    end
  end
end
