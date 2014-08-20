# encoding: utf-8

# The MIT License (MIT)
# Copyright (c) 2014 Andreas Schmidt, andreas@de-wiring.net
#

# Wire module
module Wire
  # Base class for up/down commands
  class UpDownCommand < BaseCommand
    # generic method, calls run_on_project_zones for
    # all zones in model
    def run_on_project
      zones = @project.get_element('zones')

      # iterates all zones, descend into zone
      # for further checks, mark all those bad
      # zones, decide upon boolean return flag
      (run_on_project_zones(zones)
      .each do |_zone_name, zone_data|
        # error occured in run_on_zone call. Lets mark this
        zone_data.store :status, :failed

      end.size > 0)
    end

    # returns networks from given +networks+ array that
    # belong to +zone_name+
    # params:
    # +networks+:  array of all networks
    # +zone_name+: name of desired zone
    # return:
    # # => [Array] of networks for given zone
    def self.get_networks_for_zone(networks, zone_name)
      # select networks in given zone only
      networks.select do |_, network_data|
        network_data[:zone] == zone_name
      end
    end
  end
end
