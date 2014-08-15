# encoding: utf-8

# Wire module
module Wire
  # SpecCommand generates a serverspec output for
  # given model which tests all model elements
  # optionally runs serverspec
  class SpecCommand < BaseCommand
    attr_accessor :project
    attr_accessor :target_dir

    # spec_code will contain all serverspec
    # code blocks, ready to be written to file
    attr_accessor :spec_code

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
      spec_writer = SpecWriter.new(target_specdir, @spec_code)
      spec_writer.write

      run_serverspec(target_specdir) if @params[:auto_run]
    end

    # executes serverspec in its target directory
    # TODO: stream into stdout instead of Kernel.``
    def run_serverspec(target_specdir)
      $log.debug 'Running serverspec'
      cmd = "cd #{target_specdir} && rake spec"
      $log.debug "cmd=#{cmd}"
      puts `#{cmd}`
    end

    # run verification on zones
    def run_on_project_zones(zones)
      zones.select do |zone_name, _|
        $log.debug("Creating specs for zone #{zone_name} ...")
        run_on_zone(zone_name)
        $log.debug("Done for zone #{zone_name} ...")
      end
    end

    # run verification in given zone:
    # - check if bridges exist for all networks in
    #   this zone
    def run_on_zone(zone_name)
      networks = @project.get_element('networks')

      # select networks in current zone only
      networks_in_zone = networks.select do|_, network_data|
        network_data[:zone] == zone_name
      end
      networks_in_zone.each do |network_name, network_data|
        bridge_name = network_name

        $log.debug("Creating specs for network #{bridge_name}")

        template = SpecTemplates.build_template__bridge_exists
        erb = ERB.new(template, nil, '%')
        @spec_code << erb.result(binding)

        ip = network_data[:hostip]
        if ip
          template = SpecTemplates.build_template__ip_is_up
          erb = ERB.new(template, nil, '%')
          @spec_code << erb.result(binding)
        end

        $log.debug("Done for network #{bridge_name}")
      end
    end
  end

  # SpecWriter is able to create a directory
  # structure according to basic serverspec
  # needs and fill in the templates
  class SpecWriter
    # create SpecWriter in target directory
    def initialize(target_dir, spec_contents)
      @target_dir = target_dir
      @spec_contents = spec_contents
    end

    def write
      ensure_directory_structure
      ensure_files

      $log.info "Serverspecs written to #{@target_dir}. Run:"
      $log.info "( cd #{@target_dir}; rake spec )"
      $log.info 'To run automatically, use --run'
    end

    def ensure_directory_structure
      ensure_directory @target_dir
      ensure_directory File.join(@target_dir, 'spec')
      ensure_directory File.join(@target_dir, 'spec', 'localhost')
    end

    # writes template to file
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

    def ensure_directory(target_dir)
      return if File.exist?(target_dir)
      begin
        FileUtils.mkdir_p(target_dir)
      rescue => excpt
        $stderr.puts "ERROR: Unable to create #{target_dir}: #{excpt}"
      end
    end

    def file?(target_file)
      File.exist?(target_file) && File.file?(target_file)
    end
  end
end
