# encoding: utf-8

# The MIT License (MIT)
# Copyright (c) 2014 Andreas Schmidt, andreas@de-wiring.net
#

# Wire module
module Wire
  # Run validations on network model part
  class NetworksValidation < ValidationBase
    # run validation steps on network elements
    # returns
    # - nil, results in errors of ValidationBase
    def run_validations
      networks_attached_to_zones?
      duplicate_networks_found?
      missing_network_def_found?
      nonmatching_hostips_found?
    end

    # ensures that all networks are attached to a zone
    def networks_attached_to_zones?
      zones = @project.get_element('zones')
      @project.get_element('networks').each do |network_name, network_data|
        zone = network_data[:zone]
        type = 'network'
        name = network_name
        if !zone
          mark('Network is not attached to a zone', type, name)
        else
          mark('Network has invalid zone', type, name) unless zones.key?(zone)
        end
      end
    end

    # ensures that all network ranges are unique
    def duplicate_networks_found?
      dup_map = {}
      @project.get_element('networks').each do |network_name, network_data|
        nw = network_data[:network]
        dupe_name = dup_map[nw]
        mark("Network range #{nw} used in more than one network (#{dupe_name})",
             'network', network_name) if dupe_name
        dup_map.store nw, network_name
      end
    end

    # ensures that all networks have their network range defined
    def missing_network_def_found?
      @project.get_element('networks').each do |network_name, network_data|
        nw = network_data[:network]
        mark("Network #{network_name} has no network ip range.",
             'network', network_name) unless nw
      end
    end

    # ensures that all networks with hostips have their hostip
    # within the network range of its network, i.e. 10.10.1.1 for 10.10.1.0/24
    def nonmatching_hostips_found?
      @project.get_element('networks').each do |network_name, network_data|
        network = network_data[:network]
        host_ip = network_data[:hostip]
        next unless network && host_ip

        host_ip_ip = IPAddr.new(host_ip)
        network_ip = IPAddr.new(network)

        mark("Network Host ip #{host_ip} is not within network range" \
          "#{network} of network #{network_name}", 'network', network_name) unless
            host_ip_ip.in_range_of?(network_ip)
      end
    end
  end
end
