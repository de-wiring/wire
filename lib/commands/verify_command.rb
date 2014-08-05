# encoding: utf-8

# Wire module
module Wire
  # Verify Command reads yaml, parses model elements
  # and checks if given elements are present on the system
  # params:
  # - :target_dir
  class VerifyCommand < BaseCommand
    def run(params = {})
      target_dir = params[:target_dir]
      puts "Verifying model in #{target_dir}"
      @findings = []

      # load it first
      begin
        loader = ProjectYamlLoader.new
        @project = loader.load_project(target_dir)

        run_on_project

        $log.debug? && pp(@project)
      rescue => load_execption
        $log.error "Unable to load project model from #{target_dir}"
        $log.debug? && puts(load_execption.backtrace)

        return ['No project model file(s) found.']
      end
      @findings
    end

    def mark(msg, type, element_name, element_data)
      @findings <<
          VerificationError.new(msg, type,
                                element_name, element_data)
    end

    def run_on_project
      zones = @project.get_element('zones')

      # iterates all zones, descend into zone
      # for further checks, mark all those bad
      # zones, decide upon boolean return flag
      (run_on_project_zones(zones)
        .each do |zone_name, zone_data|
          # error occured in run_on_zone call. Lets mark this
          zone_data.store :status, :failed
          mark("Not all elements of zone #{zone_name} are valid.",
               :zone, zone_name, zone_data)
        end.size > 0)
    end

    # run verification on zones
    def run_on_project_zones(zones)
      zones.select do |zone_name, _|
        $log.debug("Verifying zone #{zone_name} ...")
        run_on_zone(zone_name) == false
      end
    end

    # run verification in given zone:
    # - check if bridges exist for all networks in
    #   this zone
    def run_on_zone(zone_name)
      b_verify_ok = true
      networks = @project.get_element('networks')

      # select networks in current zone only
      networks_in_zone  = networks.select { |_, network_data| network_data[:zone] == zone_name }
      networks_in_zone.each do |network_name, network_data|
        $log.debug("Verifying network #{network_name}")

        bridge_name = network_name

        # we should have a bridge with that name.
        bridge_resource = Wire::Resource::OVSBridge.new(bridge_name)
        if bridge_resource.exist?
          puts "Bridge #{bridge_name} exists.".color(:green)
          network_data.store :status, :ok
        else
          puts "Bridge #{bridge_name} does not exist.".color(:red)

          network_data.store :status, :failed

          b_verify_ok = false
          mark("Bridge #{bridge_name} does not exist.",
               :network, network_name, network_data)
        end
      end
      b_verify_ok
    end
  end
end
