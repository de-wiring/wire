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
    # run on zones
    def run_on_project_zones(zones)
      zones.select do |zone_name, _|
        $log.debug("Bringing down zone #{zone_name} ...")
        run_on_zone(zone_name) == false
      end
    end

    # run in given zone:
    # returns:
    # - bool: true if successful, false otherwise
    def run_on_zone(zone_name)
      b_result = true

      networks = @project.get_element('networks')

      # select networks in current zone only
      networks_in_zone = UpDownCommand.get_networks_for_zone(networks, zone_name)
      networks_in_zone.each do |network_name, network_data|
        $log.debug("Bringing down network #{network_name}")

        # if we have a host ip on that bridge, take it down first
        hostip = network_data[:hostip]
        if hostip
          # if the hostip is not in cidr, take netmask
          # from network entry, add to hostip
          hostip = ensure_hostip_netmask(hostip, network_data)

          success = handle_hostip(network_name, hostip)
          b_result = false unless success
        end

        # we should have a bridge with that name.
        success = handle_bridge(network_name)
        b_result = false unless success
      end
      b_result
    end

    # take bridge down
    def handle_bridge(bridge_name)
      bridge_resource = Wire::Resource::ResourceFactory.instance.create(:ovsbridge, bridge_name)
      if bridge_resource.down?
        outputs 'DOWN', "Bridge #{bridge_name} already down.", :ok2
      else
        bridge_resource.down
        if bridge_resource.down?
          outputs 'DOWN', "Bridge #{bridge_name} down/removed.", :ok
        else
          outputs 'DOWN', "Error bringing down bridge #{bridge_name}.", :err
          b_result = false
        end

      end
      b_result
    end

    # remove ip from bridge interface
    def handle_hostip(bridge_name, hostip)
      b_result = true

      bridge_resource = Wire::Resource::ResourceFactory.instance.create(:ovsbridge, bridge_name)
      if bridge_resource.down?
        outputs 'DOWN', "Bridge #{bridge_name} already down, will not care about ip", :ok2
        return b_result
      end

      # we should have a bridge with that name.
      hostip_resource = Wire::Resource::ResourceFactory
      .instance.create(:bridgeip, hostip, bridge_name)
      if hostip_resource.down?
        outputs 'DOWN', "IP #{hostip} on bridge #{bridge_name} already down.", :ok2
      else
        hostip_resource.down
        if hostip_resource.down?
          outputs 'DOWN', "IP #{hostip} on bridge #{bridge_name} down/removed.", :ok
        else
          outputs 'DOWN', "Error taking down ip #{hostip} on bridge #{bridge_name}.", :err
          b_result = false
        end

      end
      b_result
    end
  end
end
