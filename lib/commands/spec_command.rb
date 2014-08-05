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

      # use the specwrite class to write a complete
      # serverspec example in a subdirectory(serverspec)
      target_specdir = File.join(target_dir, 'serverspec')
      spec_writer = SpecWriter.new(target_specdir, @spec_code)
      spec_writer.write

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
      networks_in_zone = networks.select do|_, network_data|
        network_data[:zone] == zone_name
      end
      networks_in_zone.each do |network_name, _|
        $log.debug("Creating specs for network #{network_name}")

        bridge_name = network_name

        template = SpecTemplates.get_template__bridge_exists(zone_name, bridge_name)
        erb = ERB.new(template, nil, '%')
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

    def self.template_spec_helper
      <<ERB
require 'serverspec'
require 'rspec/its'

include SpecInfra::Helper::Exec
include SpecInfra::Helper::DetectOS

RSpec.configure do |c|
  if ENV['ASK_SUDO_PASSWORD']
    require 'highline/import'
    c.sudo_password = ask("Enter sudo password: ") { |q| q.echo = false }
  else
    c.sudo_password = ENV['SUDO_PASSWORD']
  end
end
ERB
    end

    def self.template_rakefile
      <<ERB
require 'rake'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = 'spec/*/*_spec.rb'
  t.rspec_opts = '--format documentation --color'
end

task :default => :spec
ERB
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
    end

    def ensure_directory_structure
      ensure_directory @target_dir
      ensure_directory File.join(@target_dir, 'spec')
      ensure_directory File.join(@target_dir, 'spec', 'localhost')
    end

    def ensure_files
      rakefile_name = File.join(@target_dir, 'Rakefile')
      file?(rakefile_name) || File.open(rakefile_name, 'w') do |file|
        template = SpecTemplates.template_rakefile
        erb = ERB.new(template, nil, '%')
        file.puts(erb.result(binding))
      end

      spechelper_name = File.join(@target_dir, 'spec', 'spec_helper.rb')
      file?(spechelper_name) || File.open(spechelper_name, 'w') do |file|
        template = SpecTemplates.template_spec_helper
        erb = ERB.new(template, nil, '%')
        file.puts(erb.result(binding))
      end

      specfile_name = File.join(@target_dir, 'spec', 'localhost', 'wire_spec.rb')
      File.open(specfile_name, 'w') do |file|
        template = <<ERB
require 'spec_helper.rb'

# begin of generated specs

<%= @spec_contents.join('\n') %>

# end of spec file
ERB
        erb = ERB.new(template, nil, '%')
        file.puts(erb.result(binding))
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
