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
        STDERR.puts e.inspect
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

  # SpecWriter is able to create a directory
  # structure according to basic serverspec
  # needs and fill in the templates
  class SpecWriter
    # create SpecWriter in +target_dir+ directory
    # with given +spec_contents+
    def initialize(target_dir, spec_contents)
      @target_dir = target_dir
      @spec_contents = spec_contents
    end

    # writes spec to disk
    def write
      ensure_directory_structure
      ensure_files
    end

    # make sure that we have a rspec-conformant dir structure
    def ensure_directory_structure
      ensure_directory @target_dir
      ensure_directory File.join(@target_dir, 'spec')
      ensure_directory File.join(@target_dir, 'spec', 'localhost')
    end

    # writes erb +template+ to open +file+ object
    def write_template(template, file)
      erb = ERB.new(template, nil, '%')
      file.puts(erb.result(binding))
    end

    # ensures that all serverspec skeleton files such as
    # Rakefile, spec_helper etc. exist
    # Then writes the models specification files into the
    # skeleton
    def ensure_files
      rakefile_name = File.join(@target_dir, 'Rakefile')
      file?(rakefile_name) || File.open(rakefile_name, 'w') do |file|
        write_template(SpecTemplates.template_rakefile, file)
      end

      spechelper_name = File.join(@target_dir, 'spec', 'spec_helper.rb')
      file?(spechelper_name) || File.open(spechelper_name, 'w') do |file|
        write_template(SpecTemplates.template_spec_helper, file)
      end

      specfile_name = File.join(@target_dir, 'spec', 'localhost', 'wire_spec.rb')
      File.open(specfile_name, 'w') do |file|
        template = <<ERB
require 'spec_helper.rb'

# begin of generated specs

<%= @spec_contents.join('\n') %>

# end of spec file
ERB
        write_template(template, file)
      end
    end

    private

    # make sure that +target_dir+ exists
    def ensure_directory(target_dir)
      return if File.exist?(target_dir)
      begin
        FileUtils.mkdir_p(target_dir)
      rescue => excpt
        $log.error "ERROR: Unable to create #{target_dir}: #{excpt}"
      end
    end

    # checks if +target_file+ exists
    def file?(target_file)
      File.exist?(target_file) && File.file?(target_file)
    end
  end
end
