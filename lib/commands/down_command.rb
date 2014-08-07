# encoding: utf-8

# Wire module
module Wire
  # DownCommand reads yaml, parses model elements
  # and brings all defined model elements "down", that is
  # stopping and removing bridges, containers etc.
  # - :target_dir
  class DownCommand < BaseCommand
    # runs the command, according to parameters
    def run(params = {})
      target_dir = params[:target_dir]
      puts "Bringing down model in #{target_dir}"
      # load it first
      begin
        loader = ProjectYamlLoader.new
        @project = loader.load_project(target_dir)

        run_on_project

        $log.debug? && pp(@project)
      rescue => load_execption
        $log.error "Unable to load project model from #{target_dir}"
        $log.debug? && puts(load_execption.backtrace)

        return false
      end
      true
    end

    def run_on_project
      zones = @project.get_element('zones')

      # iterates all zones, descend into zone
      # for further checks, mark all those bad
      # zones, decide upon boolean return flag
      (run_on_project_zones(zones)
        .each do |_, zone_data|
          # error occured in run_on_zone call. Lets mark this
          zone_data.store :status, :failed

        end.size > 0)
    end

    # run on zones
    def run_on_project_zones(zones)
      zones.select do |zone_name, _|
        $log.debug("Bringing down zone #{zone_name} ...")
        run_on_zone(zone_name) == false
      end
    end

    # run in given zone:
    # returns:
    # - bool: true if successful, false otherwise
    def run_on_zone(zone_name)
      b_result = true

      networks = @project.get_element('networks')

      # select networks in current zone only
      networks_in_zone = networks.select do |_, network_data|
        network_data[:zone] == zone_name
      end

      networks_in_zone.each do |network_name, _|
        $log.debug("Bringing down network #{network_name}")

        bridge_name = network_name

        # we should have a bridge with that name.
        bridge_resource = Wire::Resource::OVSBridge.new(bridge_name)
        if bridge_resource.down?
          puts "Bridge #{bridge_name} already down.".color(:green)
        else
          bridge_resource.down
          if bridge_resource.down?
            puts "Bridge #{bridge_name} down/removed.".color(:green)
          else
            puts "Error bringing down bridge #{bridge_name}.".color(:red)
            b_result = false
          end

        end
      end
      b_result
    end
  end
end
