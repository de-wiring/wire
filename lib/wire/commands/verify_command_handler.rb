# encoding: utf-8

# The MIT License (MIT)
# Copyright (c) 2014 Andreas Schmidt, andreas@de-wiring.net
#

# Wire module
module Wire
  # handle_xxx methods for VerifyCommand
  class VerifyCommandHandler < BaseCommand
    # runs verification for a bridge resource identified by
    # +bridge_name+
    # Returns
    # - [Bool] true if bridge exists
    def handle_bridge(bridge_name)
      bridge_resource = Wire::Resource::ResourceFactory.instance.create(:ovsbridge, bridge_name)
      if bridge_resource.exist?
        outputs 'VERIFY', "Bridge \'#{bridge_name}\' exists.", :ok
        state.update(:bridge, bridge_name, :up)
        return true
      else
        outputs 'VERIFY', "Bridge \'#{bridge_name}\' does not exist.", :err
        state.update(:bridge, bridge_name, :down)
        return false
      end
    end

    # runs verification for a ip resource identified by
    # +bridge_name+ and +host_ip+
    # Returns
    # - [Bool] true if hostip if up on bridge
    def handle_hostip(bridge_name, hostip)
      hostip_resource = Wire::Resource::ResourceFactory
        .instance.create(:bridgeip, hostip, bridge_name)
      if hostip_resource.up?
        outputs 'VERIFY', "IP \'#{hostip}\' on bridge \'#{bridge_name}\' exists.", :ok
        state.update(:hostip, hostip, :up)
        return true
      else
        outputs 'VERIFY', "IP \'#{hostip}\' on bridge \'#{bridge_name}\' does not exist.", :err
        state.update(:hostip, hostip, :down)
        return false
      end
    end

    # runs verification for dnsmasqs dhcp resource
    # Returns
    # - [Bool] true if dhcp setup is valid
    def handle_dhcp(zone_name, network_name, network_entry, address_start, address_end)
      resource = Wire::Resource::ResourceFactory
        .instance.create(:dhcpconfig, "wire__#{zone_name}", network_name,
                         network_entry, address_start, address_end)
      if resource.up?
        outputs 'VERIFY', "dnsmasq/dhcp config on network \'#{network_name}\' is valid.", :ok
        state.update(:dnsmasq, network_name, :up)
        return true
      else
        outputs 'VERIFY', "dnsmasq/dhcp config on network \'#{network_name}\' is not valid.", :err
        state.update(:dnsmasq, network_name, :down)
        return false
      end
    end

    # runs verification for appgroups
    # Returns
    # - [Bool] true if appgroup setup is ok
    def handle_appgroup(_zone_name, appgroup_name, appgroup_entry, target_dir)
      # get path
      controller_entry = appgroup_entry[:controller]

      if controller_entry[:type] == 'fig'
        fig_path = File.join(File.expand_path(target_dir), controller_entry[:file])

        resource = Wire::Resource::ResourceFactory
          .instance.create(:figadapter, "#{appgroup_name}", fig_path)
        if resource.up?
          outputs 'VERIFY', "appgroup \'#{appgroup_name}\' is running.", :ok
          state.update(:appgroup, appgroup_name, :up)
          return true
        else
          outputs 'VERIFY', "appgroup \'#{appgroup_name}\' is not running.", :err
          state.update(:appgroup, appgroup_name, :down)
          return false
        end
      end

      $log.error "Appgroup not handled, unknown controller type #{controller_entry[:type]}"
      false
    end

    # runs verification for container network attachment
    # Params:
    # ++_zone_name++: Name of zone
    # ++networks++: Array of networks names, what to attach
    # ++appgroup_name++: Name of appgroup
    # ++appgroup_entry++: appgroup hash
    # ++target_dir++: project target dir
    # Returns
    # - [Bool] true if appgroup setup is ok
    def handle_network_attachments(_zone_name, networks, appgroup_name,
                                   appgroup_entry, target_dir)
      # query container ids of containers running here
      # get path
      controller_entry = appgroup_entry[:controller]

      container_ids = []

      if controller_entry[:type] == 'fig'
        fig_path = File.join(File.expand_path(target_dir), controller_entry[:file])

        resource = Wire::Resource::ResourceFactory
        .instance.create(:figadapter, "#{appgroup_name}", fig_path)

        container_ids = resource.up_ids || []
        $log.debug "Got #{container_ids.size} container id(s) from adapter"
      end

      #
      resource = Wire::Resource::ResourceFactory
      .instance.create(:networkinjection, appgroup_name, networks.keys, container_ids)
      if resource.up?
        outputs 'VERIFY', "appgroup \'#{appgroup_name}\' has network(s) " \
        "\'#{networks.keys.join(',')}\' attached.", :ok
        state.update(:appgroup, appgroup_name, :up)
        return true
      else
        outputs 'VERIFY', "appgroup \'#{appgroup_name}\' does not have " \
        "all networks \'#{networks.keys.join(',')}\' attached.", :err
        state.update(:appgroup, appgroup_name, :down)
        return false
      end
    end
  end
end
