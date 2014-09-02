# encoding: utf-8

# The MIT License (MIT)
# Copyright (c) 2014 Andreas Schmidt, andreas@de-wiring.net
#

# Wire module
module Wire
  # Base class for up/down commands
  class UpDownCommand < BaseCommand
    # generic method, calls run_on_project_zones for
    # all zones in model
    def run_on_project
      zones = @project.get_element('zones')

      # iterates all zones, descend into zone
      # for further checks, mark all those bad
      # zones, decide upon boolean return flag
      (run_on_project_zones(zones)
      .each do |_zone_name, zone_data|
        # error occured in run_on_zone call. Lets mark this
        zone_data.store :status, :failed

      end.size > 0)
    end

    # run on all given +zones+
    # Returns [Hash] of zones that failed.
    def run_on_project_zones(zones)
      zones.select do |zone_name, _|
        $log.debug("Processing zone #{zone_name} ...")
        run_on_zone(zone_name) == false
      end
    end

    # calls handle_appgroup on +handler+ for all appgroups in
    # zone given by +zone_name+
    # Returns
    # Result as bool
    def default_run_on_appgroup_in_zone(zone_name, handler)
      b_result = true

      appgroups_in_zone = objects_in_zone('appgroups', zone_name)
      appgroups_in_zone.each do |appgroup_name, appgroup_data|
        $log.debug("Processing appgroup \'#{appgroup_name}\'")

        success = handler.handle_appgroup(zone_name,
                                          appgroup_name, appgroup_data,
                                          @project.target_dir)
        b_result &= success
      end
      b_result
    end

    # if dhcp is part of given +network_data+, use
    # +handler+ to process it.
    # +zone_name+:: Name of zone
    # +network_name+:: Name of network
    def default_handle_dhcp(zone_name, network_name, network_data, handler)
      dhcp_data = network_data[:dhcp]
      return true unless dhcp_data

      $log.debug 'Processing dhcp/dnsmasq ...'
      handler.handle_dhcp(zone_name,
                          network_name, network_data,
                          dhcp_data[:start], dhcp_data[:end])
    end

    # if host ip is enabled for given network (+network_name+, +network_data+)
    # use +handler+ to process it
    def default_handle_hostip(network_name, network_data, handler)
      hostip = network_data[:hostip]
      return true unless hostip

      $log.debug "Processing host ip on network #{network_name} ..."

      # if the hostip is not in cidr, take netmask
      # from network entry, add to hostip
      hostip = ensure_hostip_netmask(hostip, network_data)

      # forward to handler
      handler.handle_hostip(network_name, hostip)
    end

    # returns networks from given +networks+ array that
    # belong to +zone_name+
    # params:
    # +networks+:  array of all networks
    # +zone_name+: name of desired zone
    # returns:
    # # => [Array] of networks for given zone
    def self.get_networks_for_zone(networks, zone_name)
      # select networks in given zone only
      networks.select do |_, network_data|
        network_data[:zone] == zone_name
      end
    end

    # if the hostip is not in cidr, take netmask
    # from network entry, add to hostip
    # params:
    # +host_ip+ i.e. 192.168.10.1
    # +network_data+ network data object, to take netmask from :network element
    def ensure_hostip_netmask(host_ip, network_data)
      return host_ip  if host_ip =~ /[0-9\.]+\/[0-9]+/

      match_data = network_data[:network].match(/[0-9\.]+(\/[0-9]+)/)
      if match_data && match_data.size >= 2
        netmask = match_data[1]
        $log.debug "Adding netmask #{netmask} to host-ip #{host_ip}"
        return "#{host_ip}#{netmask}"
      else
        $log.error "host-ip #{host_ip} is missing netmask, and none given in network."
        return host_ip
      end
    end
  end
end
