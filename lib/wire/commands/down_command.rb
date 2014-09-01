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
      b_result &= default_run_on_appgroup_in_zone(zone_name, @handler)

      # select networks in current zone only
      networks_in_zone = UpDownCommand.get_networks_for_zone(networks, zone_name)
      networks_in_zone.each do |network_name, network_data|
        $log.debug("Bringing down network #{network_name}")

        # if we have dhcp, unconfigure dnsmasq
        b_result &= default_handle_dhcp(zone_name, network_name, network_data, @handler)

        # if we have a host ip on that bridge, take it down first
        b_result &= default_handle_hostip(network_name, network_data, @handler)

        # we should have a bridge with that name.
        success = @handler.handle_bridge(network_name)
        b_result &= success
      end
      b_result
    end
  end

  # implements handle_xxx methods for DownCommand
  class DownCommandHandler < BaseCommand
    # take bridge down
    def handle_bridge(bridge_name)
      bridge_resource = Wire::Resource::ResourceFactory.instance.create(:ovsbridge, bridge_name)
      if bridge_resource.down?
        outputs 'DOWN', "Bridge #{bridge_name} already down.", :ok2
        return true
      end

      bridge_resource.down
      if bridge_resource.down?
        outputs 'DOWN', "Bridge #{bridge_name} down/removed.", :ok
        state.update(:bridge, bridge_name, :down)
      else
        outputs 'DOWN', "Error bringing down bridge #{bridge_name}.", :err
        b_result = false
      end

      b_result
    end

    # remove ip from bridge interface
    def handle_hostip(bridge_name, hostip)
      b_result = true

      bridge_resource = Wire::Resource::ResourceFactory.instance.create(:ovsbridge, bridge_name)
      if bridge_resource.down?
        outputs 'DOWN', "Bridge #{bridge_name} already down, will not care about ip", :ok2
        return true
      end

      # we should have a bridge with that name.
      hostip_resource = Wire::Resource::ResourceFactory
      .instance.create(:bridgeip, hostip, bridge_name)
      if hostip_resource.down?
        outputs 'DOWN', "IP #{hostip} on bridge #{bridge_name} already down.", :ok2
      end

      hostip_resource.down
      if hostip_resource.down?
        outputs 'DOWN', "IP #{hostip} on bridge #{bridge_name} down/removed.", :ok
        state.update(:hostip, hostip, :down)
      else
        outputs 'DOWN', "Error taking down ip #{hostip} on bridge #{bridge_name}.", :err

        b_result = false
      end

      b_result
    end

    # unconfigures dnsmasq for dhcp
    # params:
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
      if resource.down?
        outputs 'DOWN', "dnsmasq/dhcp config on network \'#{network_name}\' is already down.", :ok2
        return true
      end

      resource.down
      if resource.down?
        outputs 'DOWN', "dnsmasq/dhcp config on network \'#{network_name}\' is down.", :ok
        state.update(:dnsmasq, network_name, :down)
        return true
      else
        outputs 'DOWN', 'Error unconfiguring dnsmasq/dhcp ' \
        "config on network \'#{network_name}\'.", :err
        return false
      end
    end

    # take the appgroups' controller and directs methods to
    # it. First checks if appgroup is down. If so, ok. If not, take it down
    # and ensure that it's down
    # Params:
    # +zone_name+:: Name of zone
    # +appgroup_name+:: Name of Appgroup
    # +appgroup_entry+:: Appgroup data from model
    # +target_dir+:: Target directory (where fig file is located)
    def handle_appgroup(zone_name, appgroup_name, appgroup_entry, target_dir)
      # get path
      controller_entry = appgroup_entry[:controller]

      if controller_entry[:type] == 'fig'
        return handle_appgroup__fig(zone_name, appgroup_name, appgroup_entry, target_dir)
      end

      $log.error "Appgroup not handled for zone #{zone_name}, " \
      "unknown controller type #{controller_entry[:type]}"
      false
    end

    # implement appgroup handling for fig controller
    # Params:
    # +zone_name+:: Name of zone
    # +appgroup_name+:: Name of Appgroup
    # +appgroup_entry+:: Appgroup data from model
    # +target_dir+:: Target directory (where fig file is located)
    def handle_appgroup__fig(zone_name, appgroup_name, appgroup_entry, target_dir)
      # get path
      controller_entry = appgroup_entry[:controller]

      fig_path = File.join(File.expand_path(target_dir), controller_entry[:file])

      resource = Wire::Resource::ResourceFactory
      .instance.create(:figadapter, "#{appgroup_name}", fig_path)

      if resource.down?
        outputs 'DOWN', "appgroup \'#{appgroup_name}\' for zone #{zone_name} is already down.", :ok2
        return true
      end

      b_result = false
      resource.down
      if resource.down?
        outputs 'DOWN', "appgroup \'#{appgroup_name}\' for zone #{zone_name} is down.", :ok
        state.update(:appgroup, appgroup_name, :down)
        b_result = true
      else
        outputs 'DOWN', "Error taking down appgroup \'#{appgroup_name}\' for zone #{zone_name}.",
                :err
        b_result = false
      end

      b_result
    end
  end
end
