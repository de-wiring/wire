# encoding: utf-8

# The MIT License (MIT)
# Copyright (c) 2014 Andreas Schmidt, andreas@de-wiring.net
#

# Wire module
module Wire
  # Verify Command reads yaml, parses model elements
  # and checks if given elements are present on the system
  # rubocop:disable ClassLength
  class VerifyCommand < BaseCommand
    # +project+:: to operate upon
    # +findings+:: is an array of potential errors that occured
    # during verification run
    attr_accessor :project, :findings

    # set up with empty findings arraay
    def initialize
      @findings = []
    end

    # add a finding to the findings array
    # params:
    # +msg+::           what went wrong
    # +type+::          element type, i.e. Network
    # +element_name+::  element_name
    # +element_data+::  map of details, from model
    def mark(msg, type, element_name, element_data)
      @findings <<
          VerificationError.new(msg, type,
                                element_name, element_data)
    end

    # run verification on whole project
    # iterates all zones, descend into zone
    # verification
    # returns:
    # - [bool]  true = verification ok
    def run_on_project
      zones = @project.get_element('zones')

      # iterates all zones, descend into zone
      # for further checks, mark all those bad
      # zones, decide upon boolean return flag
      (run_on_project_zones(zones)
        .each do |zone_name, zone_data|
          # error occured in run_on_zone call. Lets mark this
          zone_data.store :status, :failed
          mark("Not all elements of zone \'#{zone_name}\' are valid.",
               :zone, zone_name, zone_data)
        end.size > 0)
    end

    # run verification on given +zones+
    def run_on_project_zones(zones)
      zones.select do |zone_name, _|
        $log.debug("Verifying zone #{zone_name} ...")
        b_zone_res = run_on_zone(zone_name)

        if b_zone_res
          outputs 'VERIFY', "Zone \'#{zone_name}\' verified successfully", :ok
        else
          outputs 'VERIFY', "Zone \'#{zone_name}\' NOT verified successfully", :err
        end

        b_zone_res == false
      end
    end

    # run verification for given +zone_name+:
    # - check if bridges exist for all networks in
    #   this zone
    def run_on_zone(zone_name)
      networks = @project.get_element('networks')

      b_verify_ok = true

      # select networks in current zone only
      networks_in_zone = networks.select do |_, network_data|
        network_data[:zone] == zone_name
      end
      # verify these networks
      b_verify_ok = false unless verify_networks(networks_in_zone, zone_name)

      # select appgroups in this zone and verify them
      appgroups_in_zone = objects_in_zone('appgroups', zone_name)
      b_verify_ok = false unless verify_appgroups(appgroups_in_zone, zone_name)

      b_verify_ok
    end

    # given an array of network elements (+networks_in_zone+), this
    # method runs the verification on each network.
    # It checks the availability of a bridge and
    # the optional host ip on that bridge.
    # Params:
    # +networks_in_zone+:: Array of network data elements in desired zone
    # +zone_name+:: Name of zone
    def verify_networks(networks_in_zone, zone_name)
      b_verify_ok = true
      networks_in_zone.each do |network_name, network_data|
        $log.debug("Verifying network \'#{network_name}\'")

        bridge_name = network_name

        $log.debug 'checking bridge ...'
        # we should have a bridge with that name.
        if handle_bridge(bridge_name) == false
          network_data.store :status, :failed
          b_verify_ok = false
          mark("Bridge \'#{bridge_name}\' does not exist.",
               :network, network_name, network_data)
        else
          network_data.store :status, :ok

          hostip = network_data[:hostip]
          # if we have a host ip, then that bridge should have
          # this ip
          if hostip
            $log.debug 'checking host-ip ...'
            if handle_hostip(bridge_name, hostip) == false
              network_data.store :status, :failed
              b_verify_ok = false
              mark("Host ip \'#{hostip}\' not up on bridge \'#{bridge_name}\'.",
                   :network, network_name, network_data)
            else
              network_data.store :status, :ok
            end
          end

          # if we have dhcp, check this
          dhcp_data = network_data[:dhcp]
          if dhcp_data
            $log.debug 'checking dhcp ...'
            if handle_dhcp(zone_name, network_name, network_data,
                           dhcp_data[:start],
                           dhcp_data[:end]) == false
              network_data.store :status, :failed
              b_verify_ok = false
              mark("dnsmasq/dhcp not configured on network \'#{bridge_name}\'.",
                   :network, network_name, network_data)
            else
              network_data.store :status, :ok
            end
          end
        end
      end
      b_verify_ok
    end

    # Given a +zone_name+ and an array of +appgroups+ entries
    # this methods verifies if these appgroups are up and running
    def verify_appgroups(appgroups, zone_name)
      b_verify_ok = true

      appgroups.each do |appgroup_name, appgroup_data|
        $log.debug("Verifying appgroup \'#{appgroup_name}\'")

        if handle_appgroup(zone_name, appgroup_name, appgroup_data) == false
          appgroup_data.store :status, :failed
          b_verify_ok = false
          mark("Appgroup \'#{appgroup_name}\' does not run correctly.",
               :appgroup, appgroup_name, appgroup_data)
        else
          appgroup_data.store :status, :ok
        end
      end
      b_verify_ok
    end

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
    def handle_appgroup(_zone_name, appgroup_name, appgroup_entry)
      # get path
      controller_entry = appgroup_entry[:controller]

      if controller_entry[:type] == 'fig'
        fig_path = File.join(File.expand_path(@project.target_dir), controller_entry[:file])

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
  end
end
