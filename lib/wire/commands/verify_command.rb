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
    # allow to get access to handler object
    attr_reader :handler

    # set up with empty findings arraay
    def initialize
      @findings = []
      @handler = VerifyCommandHandler.new
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
        if @handler.handle_bridge(bridge_name) == false
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

            # if the hostip is not in cidr, take netmask
            # from network entry, add to hostip
            hostip = ensure_hostip_netmask(hostip, network_data)

            if @handler.handle_hostip(bridge_name, hostip) == false
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
            if @handler.handle_dhcp(zone_name, network_name, network_data,
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
    # It also checks container's network attachments
    def verify_appgroups(appgroups, zone_name)
      b_verify_ok = true

      appgroups.each do |appgroup_name, appgroup_data|
        $log.debug("Verifying appgroup \'#{appgroup_name}\'")

        if @handler.handle_appgroup(zone_name, appgroup_name,
                                    appgroup_data, @project.target_dir) == false
          appgroup_data.store :status, :failed
          b_verify_ok = false
          mark("Appgroup \'#{appgroup_name}\' does not run correctly.",
               :appgroup, appgroup_name, appgroup_data)
        else
          appgroup_data.store :status, :ok
        end

        next unless b_verify_ok

        zone_networks = objects_in_zone('networks', zone_name)
        if @handler.handle_network_attachments(zone_name, zone_networks,
                                               appgroup_name, appgroup_data,
                                               @project.target_dir) == false
          appgroup_data.store :status, :failed
          b_verify_ok = false
          mark("Appgroup \'#{appgroup_name}\' has missing network attachments",
               :appgroup, appgroup_name, appgroup_data)
        else
          appgroup_data.store :status, :ok
        end
      end
      b_verify_ok
    end
  end
end
