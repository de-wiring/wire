# encoding: utf-8

# The MIT License (MIT)
# Copyright (c) 2014 Andreas Schmidt, andreas@de-wiring.net
#

# Wire module
module Wire
  # Resource module
  module Resource
    # IPBinary class wraps /sbin/ip and
    # is able to parse the output and pass it
    # on in a resource style
    class IPBinary < ResourceBase
      # sets the executables map
      def initialize
        super('undefined')
        @executables = {
          :ip => '/sbin/ip'
        }
      end

      # call ip addr show and returns details
      # as a map
      # params:
      # +device+ device (i.e. bridge0 to operate on)
      # returns:
      # - detail data of device as a map
      def get_ipaddr_data(device)
        fail(ArgumentError, 'Device name not given') unless device && device.size > 0

        result = {}
        stdout = call_addr_show(device)

        # parse line-wise. first line is about the device
        arr_lines = stdout.split("\n")

        if !arr_lines || arr_lines.size == 0
          fail("No output from #{@executables[:ip]} on dev #{device}")
        end
        result.merge!(get_ipaddr_data_device(arr_lines[0]))
        result.merge!(get_ipaddr_data_link(arr_lines[0]))

        # iterate all inet lines
        parse_inet_lines(arr_lines, result)

        result
      end

      # given the array of output lines (+arr_lines+)from ip binary call,
      # this method parses the lines and adds structured detail
      # data to +result+ map
      def parse_inet_lines(arr_lines, result)
        inet_map = {}
        arr_lines[1..-1].select { |line| line =~ /inet / }.each do |line|
          inet_result = get_ipaddr_data_inet(line)
          inet_map.store inet_result[:device], inet_result
        end
        result.store(:inet, inet_map)
      end

      # calls /sbin/ip addr show <device>
      # for given device name
      def call_addr_show(device)
        LocalExecution.with(@executables[:ip],
                            ['addr', 'show', device]) do |up_exec_obj|
          up_exec_obj.run
          fail "Error on execution of #{@executables[:ip]}, " \
            "exitcode=#{up_exec_obj.exitstatus}" unless up_exec_obj.exitstatus == 0
          return up_exec_obj.stdout
        end
      end

      # runs a set of +matchers+ against given +line+ string,
      # returns results
      # params:
      # +line+: line from command output
      # +matchers+: map of regexps
      # returns:
      # - [HashMap] with keys identical to +matchers+ map
      def generic_match_data(line, matchers)
        result = {}

        matchers.each do |key, regexp|
          md = line.match regexp
          result.store(key, md[1]) if md && md.size > 1
        end

        result
      end

      # retrieve device data from input
      # params:
      # +line+: input line from /sbin/ip addr show w/ device data
      # returns:
      # [HashMap] with id, devicename, options, mtu, state and group details
      def get_ipaddr_data_device(line)
        device_matchers = {
          :id      => /^([0-9]+):/,
          :device  => /^[0-9]+: (\w+): /,
          :options => /^[0-9]+: \w+: <([\w,_]+)> /,
          :mtu     => /mtu (\w+)/,
          :state   => /state (\w+)/,
          :group   => /group (\w+)/
        }
        generic_match_data(line, device_matchers)
      end

      # retrieve link state data from input
      # params:
      # +line+: input line from /sbin/ip addr show w/ link data
      # returns:
      # [HashMap] with type, mac address and (optional) broadcast
      def get_ipaddr_data_link(line)
        link_matchers = {
          :type    => /link\/(\w+) /,
          :mac     => /link\/\w+ ([0-9:]+)/,
          :brd     => /brd ([0-9:]+)/
        }
        generic_match_data(line, link_matchers)
      end

      # retrieve inet state data from input
      # params:
      # +line+: input line from /sbin/ip addr show w/ "inet" data
      # returns:
      # [HashMap] with ip, broadcast, scope, device
      def get_ipaddr_data_inet(line)
        inet_matchers = {
          :ip      => /inet ([0-9\.]+)\//,
          :cidr    => /inet ([0-9\.\/]+) /,
          :network => /inet [0-9\.]+(\/[0-9]+) /,
          :brd     => /brd ([0-9\.]+)/,
          :scope   => /scope (\w+)/,
          :device  => / ([\w:]+)$/
        }
        generic_match_data(line, inet_matchers)
      end
    end
  end
end
