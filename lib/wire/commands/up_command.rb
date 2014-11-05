# encoding: utf-8

# The MIT License (MIT)
# Copyright (c) 2014 Andreas Schmidt, andreas@de-wiring.net
#

# Wire module
module Wire
  # UpCommand reads yaml, parses model elements
  # and brings all defined model elements "up", that is
  # starting bridges, containers etc.
  class UpCommand < UpDownCommand
    # allow to get access to handler object
    attr_reader :handler

    # initialize
    def initialize
      @handler = UpCommandHandler.new
    end

    # run in given +zone_name+:
    # returns:
    # - bool: true if successful, false otherwise
    # rubocop:disable CyclomaticComplexity
    def run_on_zone(zone_name)
      b_result = true

      networks = @project.get_element('networks')

      # select networks in current zone only
      networks_in_zone = UpDownCommand.get_networks_for_zone(networks, zone_name)
      # re-order networks_in_zone, so that vlan'd networks appear after their
      # trunk parents
      vlan_networks_in_zone = networks_in_zone.select { |_, nd| nd[:vlan] }
      non_vlan_networks_in_zone = networks_in_zone.select { |_, nd| nd[:vlan].nil? }

      [non_vlan_networks_in_zone, vlan_networks_in_zone].each do |cur_networks|
        $log.debug("Bringing up networks #{cur_networks.keys.join(',')}")
        cur_networks.each do |network_name, network_data|
          $log.debug("Bringing up network #{network_name}")

          # choose handle method (vlan or not)
          success = false
          if network_data[:vlan]
            vlanid = (network_data[:vlan])[:id]
            on_trunk = (network_data[:vlan])[:on_trunk]
            success = @handler.handle_vlan_bridge(network_name, vlanid, on_trunk)
          else
            success = @handler.handle_bridge(network_name)
          end

          b_result &= success
          if success
            # if we have a host ip on that bridge, take it down first
            b_result &= default_handle_hostip(network_name, network_data, @handler)

            # if we have dhcp, configure dnsmasq
            b_result &= default_handle_dhcp(zone_name, network_name, network_data, @handler)
          else
            $log.debug("Will not touch dependant objects of #{network_name} " \
                       'due to previous error(s)')
          end
        end
      end

      # select appgroups in this zone and bring them up
      appgroups_in_zone = objects_in_zone('appgroups', zone_name)
      appgroups_in_zone.each do |appgroup_name, appgroup_data|
        $log.debug("Processing appgroup \'#{appgroup_name}\'")

        success = handler.handle_appgroup(zone_name,
                                          appgroup_name, appgroup_data,
                                          @project.target_dir)
        b_result &= success

        # process network attachments
        zone_networks = objects_in_zone('networks', zone_name)
        success = handler.handle_network_attachments(zone_name, zone_networks,
                                                     appgroup_name, appgroup_data,
                                                     @project.target_dir, @project.vartmp_dir)
        b_result &= success
      end

      b_result
    end
  end
end
