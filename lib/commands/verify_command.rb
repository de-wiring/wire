# encoding: utf-8

# Wire module
module Wire
  # Verify Command reads yaml, parses model elements
  # and checks if given elements are present on the system
  # params:
  # - :target_dir
  class VerifyCommand < BaseCommand
    def run(params = {})
      puts "Verifying model in #{params[:target_dir]}"

      # load it first
      loader = ProjectYamlLoader.new
      project = loader.load_project(params[:target_dir])

      # run verification, collect findings
      findings = []
      run_on_project(project, findings)

      $log.debug? && pp(project)

      findings
    end

    def run_on_project(project, findings)
      zones = project.get_element('zones')

      # iterates all zones, descend into zone
      # for further checks, mark all those bad
      # zones, decide upon boolean return flag
      (run_on_project_zones(project, zones, findings)
        .each do |zone_name, zone_data|
          # error occured in run_on_zone call. Lets mark this
          zone_data.store :status, :failed
          findings <<
              VerificationError.new('Not all elements of zone are valid.',
                                    :zone, zone_name, zone_data)
        end.size > 0)
    end

    def run_on_project_zones(project, zones, findings)
      zones.select do |zone_name, _|
        $log.debug("Verifying zone #{zone_name} ...")
        run_on_zone(project, zone_name, findings) == false
      end
    end

    def run_on_zone(project, zone_name, findings)
      b_verify_ok = true
      networks = project.get_element('networks')
      networks.each do |network_name, network_data|
        next unless network_data[:zone] == zone_name

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
          findings <<
              VerificationError.new("Bridge #{bridge_name} does not exist.",
                                    :network, network_name, network_data)
        end
      end
      b_verify_ok
    end
  end
end
