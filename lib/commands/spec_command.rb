# encoding: utf-8

# Wire module
module Wire
  # Verify Command reads yaml, parses model elements
  # and checks if given elements are present on the system
  # params:
  # - :target_dir
  class SpecCommand < BaseCommand
    def run(params = {})
      target_dir = params[:target_dir]
      puts "Verifying model in #{target_dir}"

      @spec_code = []
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


      @spec_code.each do |block_text|
        puts block_text
      end

      true
    end

    def run_on_project
      zones = @project.get_element('zones')

      # iterates all zones, descend into zone
      run_on_project_zones(zones)
    end

    # run verification on zones
    def run_on_project_zones(zones)
      zones.select do |zone_name, _|
        $log.debug("Creating specs for zone #{zone_name} ...")
        run_on_zone(zone_name)
      end
    end

    # run verification in given zone:
    # - check if bridges exist for all networks in
    #   this zone
    def run_on_zone(zone_name)
      networks = @project.get_element('networks')

      # select networks in current zone only
      networks_in_zone  = networks.select { |_, network_data| network_data[:zone] == zone_name }
      networks_in_zone.each do |network_name, _|
        $log.debug("Creating specs for network #{network_name}")

        bridge_name = network_name

        template = SpecTemplates.get_template__bridge_exists(zone_name, bridge_name)
        erb = ERB.new(template,nil,"%")
        @spec_code << erb.result(binding)

      end

    end
  end

  # stateless erb template methods
  class SpecTemplates

    # rubocop:disable Lint/UnusedMethodArgument
    # :reek:UnusedParameters
    def self.get_template__bridge_exists(zone_name, bridge_name)
      <<ERB
  describe 'In zone <%= zone_name %> we should have an ovs bridge named <%= bridge_name %>' do
    describe command "sudo ovs-vsctl list-br" do
      its(:stdout) { should match /<%= bridge_name %>/ }
    end
  end
ERB
    end
  end
end
