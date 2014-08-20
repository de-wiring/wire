# encoding: utf-8

# The MIT License (MIT)
# Copyright (c) 2014 Andreas Schmidt, andreas@de-wiring.net
#

# Wire module
module Wire
  # Verify Command reads yaml, parses model elements
  # and checks if given elements are present on the system
  class VerifyCommand < BaseCommand
    # +project+ to operate upon
    # +findings+ is an array of potential errors that occured
    # during verification run
    attr_accessor :project, :findings

    # set up with empty findings arraay
    def initialize
      @findings = []
    end

    # add a finding to the findings array
    # params:
    # - +msg+   what went wrong
    # - +type+  element type, i.e. Network
    # - +element_name+  element_name
    # - +element_data+  map of details, from model
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
        end

        b_zone_res == false
      end
    end

    # run verification for given +zone_name+:
    # - check if bridges exist for all networks in
    #   this zone
    def run_on_zone(zone_name)
      networks = @project.get_element('networks')

      # select networks in current zone only
      networks_in_zone = networks.select do |_, network_data|
        network_data[:zone] == zone_name
      end
      # verify these networks
      verify_networks(networks_in_zone)
    end

    # given an array of network elements (+networks_in_zone+), this
    # method runs the verification on each network.
    # It checks the availability of a bridge and
    # the optional host ip on that bridge.
    def verify_networks(networks_in_zone)
      b_verify_ok = true
      networks_in_zone.each do |network_name, network_data|
        $log.debug("Verifying network \'#{network_name}\'")

        bridge_name = network_name

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
            if handle_hostip(bridge_name, hostip) == false
              network_data.store :status, :failed
              b_verify_ok = false
              mark("Host ip \'#{hostip}\' not up on bridge \'#{bridge_name}\'.",
                   :network, network_name, network_data)
            else
              network_data.store :status, :ok
            end
          end
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
        return true
      else
        outputs 'VERIFY', "Bridge \'#{bridge_name}\' does not exist.", :err
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
        return true
      else
        outputs 'VERIFY', "IP \'#{hostip}\' on bridge \'#{bridge_name}\' does not exist.", :err
        return false
      end
    end
  end
end
