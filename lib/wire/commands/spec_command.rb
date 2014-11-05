# encoding: utf-8

# The MIT License (MIT)
# Copyright (c) 2014 Andreas Schmidt, andreas@de-wiring.net
#

# Wire module
module Wire
  # SpecCommand generates a serverspec output for
  # given model which tests all model elements.
  # optionally runs serverspec
  class SpecCommand < BaseCommand
    # +project+ to operate on
    attr_accessor :project
    # +target_dir+ to read model from (and put specs into)
    attr_accessor :target_dir

    # spec_code will contain all serverspec
    # code blocks, ready to be written to file
    attr_accessor :spec_code

    # initializes empty spec
    def initialize
      @spec_code = []
    end

    # process specification for whole project model
    def run_on_project
      @target_dir = @params[:target_dir]
      zones = @project.get_element('zones')

      # iterates all zones, descend into zone
      run_on_project_zones(zones)

      # use the specwrite class to write a complete
      # serverspec example in a subdirectory(serverspec)
      target_specdir = File.join(@target_dir, 'serverspec')

      begin
        spec_writer = SpecWriter.new(target_specdir, @spec_code)
        spec_writer.write

        outputs 'SPEC', "Serverspecs written to #{target_specdir}. Run:"
        outputs 'SPEC', "( cd #{target_specdir}; sudo rake spec )"
        outputs 'SPEC', 'To run automatically, use --run'
      rescue => exception
        $log.error "Error writing serverspec files, #{exception}"
        STDERR.puts exception.inspect
      end

      run_serverspec(target_specdir) if @params[:auto_run]
    end

    # executes serverspec in its target directory
    # TODO: stream into stdout instead of Kernel.``
    # params:
    # +target_dir+ model and output dir
    def run_serverspec(target_specdir)
      $log.debug 'Running serverspec'
      cmd = "cd #{target_specdir} && sudo rake spec"
      $log.debug "cmd=#{cmd}"
      result = `#{cmd}`
      puts result
    end

    # run verification on +zones+
    def run_on_project_zones(zones)
      zones.select do |zone_name, _|
        $log.debug("Creating specs for zone #{zone_name} ...")
        run_on_zone(zone_name)
        $log.debug("Done for zone #{zone_name} ...")
      end
    end

    # run spec steps in given +zone_name+
    def run_on_zone(zone_name)
      networks = @project.get_element('networks')

      # select networks in current zone only
      networks_in_zone = networks.select do|_, network_data|
        network_data[:zone] == zone_name
      end
      networks_in_zone.each do |network_name, network_data|
        run_on_network_in_zone zone_name, network_name, network_data
      end

      # select application groups in current zone
      objects_in_zone('appgroups', zone_name).each do |appgroup_name, appgroup_data|
        run_on_appgroup_in_zone zone_name, appgroup_name, appgroup_data
      end
    end

    # given a network object, this generates spec
    # for it.
    # params:
    # +zone_name+  name of zone (needed for erb context)
    # +bridge_name+  name of network/bridge (needed for erb context)
    # +network_data+  network details
    # rubocop:disable Lint/UnusedMethodArgument
    # rubocop:disable Lint/UselessAssignment
    # :reek:UnusedParameters
    def run_on_network_in_zone(zone_name, bridge_name, network_data)
      $log.debug("Creating specs for network #{bridge_name}")

      template = SpecTemplates.build_template__bridge_exists
      erb = ERB.new(template, nil, '%')
      @spec_code << erb.result(binding)

      vlan = network_data[:vlan]
      if vlan
        vlanid = vlan[:id]
        on_trunk = vlan[:on_trunk]
        template = SpecTemplates.build_template__bridge_vlan_id_and_trunk
        erb = ERB.new(template, nil, '%')
        @spec_code << erb.result(binding)
      end

      # render template for hostip (if any)
      ip = network_data[:hostip]
      if ip
        template = SpecTemplates.build_template__ip_is_up
        erb = ERB.new(template, nil, '%')
        @spec_code << erb.result(binding)
      end

      # render dhcp spec (if any)
      dhcp_data = network_data[:dhcp]
      if dhcp_data
        ip_start = dhcp_data[:start]
        ip_end = dhcp_data[:end]
        hostip = ip
        template = SpecTemplates.build_template__dhcp_is_valid
        erb = ERB.new(template, nil, '%')
        @spec_code << erb.result(binding)

      end

      $log.debug("Done for network #{bridge_name}")
    end

    # given an appgroup object, this generates spec
    # for it.
    # params:
    # +zone_name+  name of zone (needed for erb context)
    # +appgroup_name+  name of appgroup (needed for erb context)
    # +appgroup_data+  appgroup details
    # rubocop:disable Lint/UnusedMethodArgument   Lint/UselessAssignment
    # :reek:UnusedParameters
    def run_on_appgroup_in_zone(zone_name, appgroup_name, appgroup_data)
      $log.debug("Creating specs for appgroup #{appgroup_name}")

      # check controller
      controller_data = appgroup_data[:controller]
      if controller_data[:type] == 'fig'
        # get fig file name
        figfile_part = controller_data[:file] || "#{zone_name}/fig.yaml"
        figfile = File.join(File.expand_path(@target_dir), figfile_part)

        template = SpecTemplates.build_template__fig_file_is_valid
        erb = ERB.new(template, nil, '%')
        @spec_code << erb.result(binding)

        template = SpecTemplates.build_template__fig_containers_are_up
        erb = ERB.new(template, nil, '%')
        @spec_code << erb.result(binding)
      end

      $log.debug("Done for appgroup #{appgroup_name}")
    end
  end
end
