# encoding: utf-8

# Wire module
module Wire
  # Base class for up/down commands
  class UpDownCommand < BaseCommand
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

    def self.get_networks_for_zone(networks, zone_name)
      # select networks in given zone only
      networks.select do |_, network_data|
        network_data[:zone] == zone_name
      end
    end
  end
end
