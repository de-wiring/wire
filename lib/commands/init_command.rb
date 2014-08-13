# encoding: utf-8

# Wire module
module Wire
  # Init Command opens an interactive console dialog
  # for initializing a model structure
  # params:
  # - :target_dir
  class InitCommand < BaseCommand
    def run(params = {})
      puts "Initializing model in #{params[:target_dir]}"

      model_data = {}
      zone_data = {}
      network_data = {}
      model_data.store :zones, zone_data
      model_data.store :networks, network_data

      zone_names = InitInteractive.ask_for_zone_names
      if zone_names.size == 0
        $stderr.puts 'ERROR: must at least have one zone'
        exit Wire.cli_exitcode(:init_bad_input)
      end
      zone_names.each do |zone_name|

        zone_detail = {
          :desc => 'Enter a short description here',
          :long_desc => 'Enter a longer description here'
        }

        zone_data.store zone_name, zone_detail

        networks = InitInteractive.ask_for_network_in_zone zone_name
        networks.each do |network_name|

          network_details = InitInteractive.ask_detail_data_for_network network_name
          network_details.merge!({ :zone => zone_name })
          network_data.store network_name, network_details
        end
      end

      # write resulting model to file
      export_model_file(model_data, params[:target_dir])
    end

    # Given a model structure and a target dir, this method
    # ensures that targetdir exists and structure contents
    # are written to individual files
    def export_model_file(model_data, target_dir)
      puts "Target dir is #{target_dir}"

      # ensure target_dir exists
      if File.exist?(target_dir)
        if File.directory?(target_dir)
          $stdout.puts "Writing output to #{target_dir}"
        else
          $stderr.puts "ERROR: Target dir #{target_dir} exists, " \
                       'but is not a directory.'
          exit Wire.cli_exitcode(:init_dir_error)
        end
      else
        begin
          FileUtils.mkdir_p(target_dir)
        rescue => excpt
          $stderr.puts "ERROR: Unable to create #{target_dir}: #{excpt}"
          exit Wire.cli_exitcode(:init_dir_error)
        end
      end

      [:zones, :networks].each do |element_sym|
        element = model_data[element_sym]
        export_element_file element_sym, element, target_dir
      end
    end

    # exports an element part of the model to a single file
    # in target_dir, as yaml.
    def export_element_file(element_sym, element_data, target_dir)
      filename = File.join(target_dir, "#{element_sym}.yaml")
      open(filename, 'w') do |out_file|
        out_file.puts(element_data.to_yaml)
      end
    end
  end

  # interactive ask_ commands
  class InitInteractive
    # ask for a comma separated list of zone names
    def self.ask_for_zone_names
      question = <<-EOF
Please enter the names of desired system zones,
as a comma-separated list:
      EOF
      puts question
      print '> '

      line = STDIN.gets.chomp

      line.split(',').map { |zone_name| zone_name.strip }
    end

    def self.ask_for_network_in_zone(zone_name)
      question = <<-EOF
  - Configuring networks in zone #{zone_name}:
  Please enter the names of logical networks
  (or leave empty if no networks desired):
      EOF
      puts question
      print '> '

      line = STDIN.gets.chomp

      line.split(',').map { |network_name| network_name.strip }
    end

    def self.ask_detail_data_for_network(network_name)
      question = <<-EOF
    = Configuring network #{network_name}
    Please enter network address in cidr (i.e.192.168.1.0/24)
      EOF
      puts question
      print '> '

      line = STDIN.gets.chomp
      result = {}

      result.store :network, line.chomp.strip

      question = <<-EOF
    Please enter ip address of this network on host (i.e.192.168.1.1)
    OR leave empty if not desired.
      EOF
      puts question
      print '> '

      line = STDIN.gets.chomp.strip

      result.store(:hostip, line) if line.size > 0

      result
    end
  end
end
