# encoding: utf-8

# The MIT License (MIT)
# Copyright (c) 2014 Andreas Schmidt, andreas@de-wiring.net
#

# Wire module
module Wire
  # Run validations on network model part
  class NetworksValidation < ValidationBase
    # run validation steps on network elements
    # returns:
    # - nil, results in errors of ValidationBase
    def run_validations
      network_names_ok?
      networks_attached_to_zones?
      duplicate_networks_found?
      missing_network_def_found?
      nonmatching_hostips_found?
      dhcp_address_ranges_valid?
      vlan_valid?
      networks_names_too_long?
    end

    # ensures that all networks are attached to a zone
    def networks_attached_to_zones?
      objects_attached_to_zones? 'networks'
    end

    # ensures that all vlan-enhanced network
    # definitions are valid:
    # - valid tag id 0..4095
    # - parent exist
    # - no dupes
    def vlan_valid?
      # check basic validity
      @project.get_element('networks').select { |_, network_data|
        network_data[:vlan]
      }.each do |network_name, network_data|
        vd = network_data[:vlan]
        vlan_id_ok = false
        begin
          vlan_id_ok = (vd && vd[:id] != nil && vd[:id] >= 0 && vd[:id] <= 4095)
        rescue
        end

        mark("Network #{network_name} has invalid or missing vlan id. set :id between 0..4095",
             'network', network_name) unless vlan_id_ok

        trunk_id_ok = false
        begin
          trunk_id_ok = ( @project.get_element('networks').select { |network_name, _|
            network_name == vd[:on_trunk] }.size == 1 )
        rescue
        end

        mark("Network #{network_name} has invalid or missing vlan trunk network. " \
             'Please point :on_trunk to an existing network.',
             'network', network_name) unless trunk_id_ok
      end


      # check dupes
      # dup_map = {}
      # @project.get_element('networks').each do |network_name, network_data|
      #   vlan_data = network_data[:vlan]
      #   next unless vlan_data
      #
      #   dupe_name = dup_map[nw]
      #
      #   mark("Network range #{nw} used in more than one network (#{dupe_name})",
      #        'network', network_name) if dupe_name
      #   dup_map.store nw, network_name
      #
    end

    # ensures that networks with names > 6 chars have
    # a short name defined, and short names are 6 chars. max.
    def networks_names_too_long?
      @project.get_element('networks').each do |network_name, network_data|
        b_short_name_ok = (network_data[:shortname] && network_data[:shortname].size <= 6)

        mark("Network name #{network_name} too long, please define a :shortname with 6 chars. max.",
             'network', network_name) if network_name.size > 6 && !b_short_name_ok
        mark("Network short name of network #{network_name} too long, please define a :shortname " \
             'with 6 chars. max.',
             'network', network_name) if network_data[:shortname] && !b_short_name_ok
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

    # ensures that all network names are valid: size 1..15
    def network_names_ok?
      @project.get_element('networks').each do |network_name, network_data|
        name_ok = (network_name.size >= 2 && network_name.size <= 15)
        mark("Network #{network_name}, name size must be 2..15 characters",
             'network', network_name) unless name_ok
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

    # ensures that if a network has dhcp set, its :start/:end address
    # ranges are within the address range of network, and a hostip is
    # given (for dnsmasq to udp-listen on it)
    # rubocop:disable CyclomaticComplexity
    def dhcp_address_ranges_valid?
      @project.get_element('networks').each do |network_name, network_data|
        network = network_data[:network]
        dhcp_data = network_data[:dhcp]
        next unless network && dhcp_data

        # do we have a host-ip on this bridge?
        host_ip = network_data[:hostip]
        if !host_ip
          mark("Network #{network_name} wants dhcp, but does not include a hostip.",
               'network', network_name)
          return false
        else
          if !dhcp_data[:start] || !dhcp_data[:end]
            mark("Network #{network_name} wants dhcp, but does not include an " \
                 'address range. Set :start, :end.',
                 'network', network_name)
            return false
          else
            check_network_ip_ranges(dhcp_data, network, network_name)
          end
        end
      end
    end

    # check ip ranges of +dhcp_data+ and given +network+
    # with name +network_name+
    def check_network_ip_ranges(dhcp_data, network, network_name)
      network_ip = IPAddr.new(network)

      # check both starting/ending ip range
      { :start => IPAddr.new(dhcp_data[:start]),
        :end   => IPAddr.new(dhcp_data[:end]) }.each do |type, data|
        mark("Network dhcp #{type} ip #{dhcp_data[type]} is not within network range" \
             "#{network} of network #{network_name}",
             'network', network_name) unless data.in_range_of?(network_ip)
      end
    rescue => e
      mark("Network dhcp ip range is not valid: #{e}", 'network', network_name)
    end
  end
end
