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
