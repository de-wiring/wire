# encoding: utf-8

# The MIT License (MIT)
# Copyright (c) 2014 Andreas Schmidt, andreas@de-wiring.net
#

# Wire module
module Wire
  # DownCommand reads yaml, parses model elements
  # and brings all defined model elements "down", that is
  # stopping and removing bridges, containers etc.
  # - :target_dir
  class DownCommand < UpDownCommand
    # allow to get access to handler object
    attr_reader :handler

    # initializes DownCommand, creates handler
    def initialize
      super
      @handler = DownCommandHandler.new
    end

    # run in given zone:
    # returns:
    # - bool: true if successful, false otherwise
    def run_on_zone(zone_name)
      b_result = true

      networks = @project.get_element('networks')

      # select appgroups in this zone and take them down first
      appgroups_in_zone = objects_in_zone('appgroups', zone_name)
      appgroups_in_zone.each do |appgroup_name, appgroup_data|
        $log.debug("Processing appgroup \'#{appgroup_name}\'")

        # process network attachments
        zone_networks = objects_in_zone('networks', zone_name)
        success = handler.handle_network_attachments(zone_name, zone_networks,
                                                     appgroup_name, appgroup_data,
                                                     @project.target_dir)
        b_result &= success

        # then take down containers
        success = handler.handle_appgroup(zone_name,
                                          appgroup_name, appgroup_data,
                                          @project.target_dir)
        b_result &= success

      end

      # select networks in current zone only
      networks_in_zone = UpDownCommand.get_networks_for_zone(networks, zone_name)
      # re-order networks_in_zone, so that vlan'd networks appear before their
      # trunk parents
      vlan_networks_in_zone = networks_in_zone.select { |network_name, network_data|
        network_data[:vlan]
      }
      non_vlan_networks_in_zone = networks_in_zone.select { |network_name, network_data|
        network_data[:vlan] == nil
      }
      [ vlan_networks_in_zone, non_vlan_networks_in_zone ].each do |networks|
        $log.debug("Bringing up networks #{networks.keys.join(',')}")

        networks.each do |network_name, network_data|
          $log.debug("Bringing down network #{network_name}")

          # if we have dhcp, unconfigure dnsmasq
          b_result &= default_handle_dhcp(zone_name, network_name, network_data, @handler)

          # if we have a host ip on that bridge, take it down first
          b_result &= default_handle_hostip(network_name, network_data, @handler)

          # we should have a bridge with that name.
          success = @handler.handle_bridge(network_name)
          b_result &= success
        end
      end

      b_result
    end
  end
end
