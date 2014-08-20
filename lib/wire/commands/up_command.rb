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
    # run on +zones+
    def run_on_project_zones(zones)
      zones.select do |zone_name, _|
        $log.debug("Bringing up zone #{zone_name} ...")
        run_on_zone(zone_name) == false
      end
    end

    # run in given +zone_name+:
    # returns:
    # - bool: true if successful, false otherwise
    def run_on_zone(zone_name)
      b_result = true

      networks = @project.get_element('networks')

      # select networks in current zone only
      networks_in_zone = UpDownCommand.get_networks_for_zone(networks, zone_name)
      networks_in_zone.each do |network_name, network_data|
        $log.debug("Bringing up network #{network_name}")

        success = handle_bridge(network_name)
        b_result = false unless success
        if success
          # go on
          host_ip = network_data[:hostip]
          if host_ip
            success = handle_hostip(network_name, host_ip)

            b_result = false unless success
          end
        else
          $log.debug("Will not touch dependant objects of #{network_name}")
        end
      end
      b_result
    end

    # bring bridge resource up, identified by
    # +bridge_name+
    # Returns
    # - [Bool] true if hostip if up on bridge
    def handle_bridge(bridge_name)
      b_result = true

      # we should have a bridge with that name.
      bridge_resource = Wire::Resource::ResourceFactory.instance.create(:ovsbridge, bridge_name)
      if bridge_resource.up?
        outputs 'UP',  "Bridge #{bridge_name} already up.", :ok2
      else
        bridge_resource.up
        if bridge_resource.up?
          outputs 'UP',  "Bridge #{bridge_name} up.", :ok
        else
          outputs 'UP',  "Error bringing up bridge #{bridge_name}.", :err
          b_result = false
        end

      end
      b_result
    end

    # bring ip resource up on device identified by
    # +bridge_name+ and +host_ip+
    # Returns
    # - [Bool] true if hostip if up on bridge
    def handle_hostip(bridge_name, hostip)
      b_result = true

      # we should have a bridge with that name.
      hostip_resource = Wire::Resource::ResourceFactory
        .instance.create(:bridgeip, hostip, bridge_name)
      if hostip_resource.up?
        outputs 'UP',  "IP #{hostip} on bridge #{bridge_name} already up.", :ok2
      else
        hostip_resource.up
        if hostip_resource.up?
          outputs 'UP',  "IP #{hostip} on bridge #{bridge_name} up.", :ok
        else
          outputs 'UP',  "Error bringing up ip #{hostip} on bridge #{bridge_name}.", :err
          b_result = false
        end

      end
      b_result
    end
  end
end
