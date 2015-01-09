# encoding: utf-8

# The MIT License (MIT)
# Copyright (c) 2014 Andreas Schmidt, andreas@de-wiring.net
#

# Wire module
module Wire
  # implements handle_xxx methods for DownCommand
  # delegates to BaseCommand.default_handle_resource for most parts
  # rubocop:disable ClassLength
  class DownCommandHandler < BaseCommand
    # take bridge down
    def handle_bridge(bridge_name)
      bridge_resource = Wire::Resource::ResourceFactory.instance.create(:ovsbridge, bridge_name)
      default_handle_resource(bridge_resource, :bridge, "Bridge \'#{bridge_name}\'", :down)
    rescue => e
      $log.error "processing bridge: #{e}"
    end

    # detaches a port +attach_port+ from bridge given by +network_name+
    def handle_port_attachment(network_name, attach_port)
      bridge_resource = Wire::Resource::ResourceFactory.instance.create(:ovsport,
                                                                        attach_port, network_name)

      default_handle_resource(bridge_resource, :ovsport,
                              "Port \'#{attach_port}\' on bridge \'#{network_name}\'", :down)
    rescue => e
      $log.error "processing port-attachment: #{e}"
    end

    # remove ip from bridge interface
    def handle_hostip(bridge_name, hostip)
      bridge_resource = Wire::Resource::ResourceFactory.instance.create(:ovsbridge, bridge_name)
      if bridge_resource.down?
        outputs 'DOWN', "Bridge #{bridge_name} already down, will not care about ip", :ok2
        return true
      end

      # we should have a bridge with that name.
      hostip_resource = Wire::Resource::ResourceFactory
      .instance.create(:bridgeip, hostip, bridge_name)
      default_handle_resource(hostip_resource, :hostip,
                              "IP \'#{hostip}\' on bridge \'#{bridge_name}\'", :down)
    rescue => e
      $log.error "processing host ip: #{e}"
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
      resource_dhcp = Wire::Resource::ResourceFactory
      .instance.create(:dhcpconfig, "wire__#{zone_name}", network_name,
                       network_entry, address_start, address_end)
      default_handle_resource(resource_dhcp, :dnsmasq,
                              "dnsmasq/dhcp config on network \'#{network_name}\'", :down)
    rescue => e
      $log.error "processing dhcp configuration: #{e}"
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
    rescue => e
      $log.error "processing appgroup: #{e}"
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

      resource_fig = Wire::Resource::ResourceFactory
      .instance.create(:figadapter, "#{appgroup_name}", fig_path)

      default_handle_resource(resource_fig, :appgroup,
                              "appgroup \'#{appgroup_name}\' for zone \'#{zone_name}\'", :down)
    rescue => e
      $log.error "processing appgroup/fig: #{e}"
    end

    # detaches networks to containers of appgroup
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

        resource_fig = Wire::Resource::ResourceFactory
        .instance.create(:figadapter, "#{appgroup_name}", fig_path)

        container_ids = resource_fig.up_ids || []
        $log.debug "Got #{container_ids.size} container id(s) from adapter"
      end

      #
      resource_nw = Wire::Resource::ResourceFactory
      .instance.create(:networkinjection, appgroup_name, networks, container_ids)

      default_handle_resource(resource_nw, :network_injection,
                              "Network(s) \'#{networks.keys.join(',')}\' in "\
                              "appgroup \'#{appgroup_name}\'", :down)
    rescue => e
      $log.error "processing network attachments: #{e}"
    end
  end
end
