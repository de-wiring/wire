# encoding: utf-8

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

      if $log.debug?
         pp project
      end
      run_on_project project

      []
    end

    def run_on_project(project)
      zones = project.get_element('zones')
      zones.each do |zone_name, _|
        $log.debug("Verifying zone #{zone_name} ...")
        run_on_zone project, zone_name
      end
    end

    def run_on_zone(project, zone_name)
      networks = project.get_element('networks')
      networks.each do |network_name, network_data|
        next unless network_data[:zone] == zone_name

        $log.debug("Verifying network #{network_name}")

        bridge_name = network_name

        # we should have a bridge with that name.
        bridge_resource = Wire::Resource::OVSBridge.new(bridge_name)
        if bridge_resource.exist?
          puts "Bridge #{bridge_name} exists.".color(:green)
        else
          puts "Bridge #{bridge_name} does not exist.".color(:red)
        end

      end
    end

  end
end

