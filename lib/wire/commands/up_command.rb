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

    # run on all given +zones+
    def run_on_project_zones(zones)
      zones.select do |zone_name, _|
        $log.debug("Bringing up zone #{zone_name} ...")
        run_on_zone(zone_name) == false
      end
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
      networks_in_zone.each do |network_name, network_data|
        $log.debug("Bringing up network #{network_name}")

        success = @handler.handle_bridge(network_name)
        b_result &= success
        if success
          # go on
          host_ip = network_data[:hostip]

          if host_ip
            $log.debug 'bringing up hostip ...'
            # if the hostip is not in cidr, take netmask
            # from network entry, add to hostip
            host_ip = ensure_hostip_netmask(host_ip, network_data)

            # try to bring it up
            success = @handler.handle_hostip(network_name, host_ip)

            b_result &= success
          end

          # if we have dhcp, configure dnsmasq
          dhcp_data = network_data[:dhcp]
          if dhcp_data
            $log.debug 'enabling dhcp ...'
            success =  @handler.handle_dhcp(zone_name,
                                            network_name, network_data,
                                            dhcp_data[:start], dhcp_data[:end])

            b_result &= success
          end

        else
          $log.debug("Will not touch dependant objects of #{network_name}")
        end
      end

      # select appgroups in this zone and bring them up
      appgroups_in_zone = objects_in_zone('appgroups', zone_name)
      appgroups_in_zone.each do |appgroup_name, appgroup_data|
        $log.debug("Bringing up appgroup \'#{appgroup_name}\'")

        success = @handler.handle_appgroup(zone_name,
                                           appgroup_name, appgroup_data,
                                           @project.target_dir)
        b_result &= success
      end

      b_result
    end
  end

  # handle_xxx methods for UpCommand
  class UpCommandHandler < BaseCommand
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
          state.update(:bridge, bridge_name, :up)
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
          state.update(:hostip, hostip, :up)
        else
          outputs 'UP',  "Error bringing up ip #{hostip} on bridge #{bridge_name}.", :err
          b_result = false
        end

      end
      b_result
    end

    # configures dnsmasq for dhcp
    # +zone_name+ name of zone
    # +network_name+ name of network (and bridge)
    # +network+ network entry
    # +address_start+ start of address range (i.e.192.168.10.10)
    # +address_end+ end of dhcp address range (i.e.192.168.10.100)
    # Returns
    # - [Bool] true if dhcp setup is valid
    def handle_dhcp(zone_name, network_name, network_entry, address_start, address_end)
      resource = Wire::Resource::ResourceFactory
      .instance.create(:dhcpconfig, "wire__#{zone_name}", network_name,
                       network_entry, address_start, address_end)
      if resource.up?
        outputs 'UP', "dnsmasq/dhcp config on network \'#{network_name}\' is already up.", :ok2
        return true
      else
        resource.up
        if resource.up?
          outputs 'UP', "dnsmasq/dhcp config on network \'#{network_name}\' is up.", :ok
          state.update(:dnsmasq, network_name, :up)
          return true
        else
          outputs 'UP', "Error configuring dnsmasq/dhcp config on network \'#{network_name}\'.",
                  :err
          return false
        end
      end
    end

    # take the appgroups' controller and directs methods to
    # it. First checks if appgroup is up. If so, ok. If not, bring it up
    # and ensure that it's up
    # Params:
    # +zone_name+:: Name of zone
    # +appgroup_name+:: Name of Appgroup
    # +appgroup_entry+:: Appgroup data from model
    def handle_appgroup(_zone_name, appgroup_name, appgroup_entry, target_dir)
      # get path
      controller_entry = appgroup_entry[:controller]

      if controller_entry[:type] == 'fig'
        fig_path = File.join(File.expand_path(target_dir), controller_entry[:file])

        resource = Wire::Resource::ResourceFactory
        .instance.create(:figadapter, "#{appgroup_name}", fig_path)

        if resource.up?
          outputs 'UP', "appgroup \'#{appgroup_name}\' is already up.", :ok2
          return true
        else
          resource.up
          if resource.up?
            outputs 'UP', "appgroup \'#{appgroup_name}\' is up.", :ok
            state.update(:appgroup, appgroup_name, :up)
            return true
          else
            outputs 'UP', "Error bringing up appgroup \'#{appgroup_name}\'.",
                    :err
            return false
          end
        end
      end

      $log.error "Appgroup not handled, unknown controller type #{controller_entry[:type]}"
      false
    end
  end
end
