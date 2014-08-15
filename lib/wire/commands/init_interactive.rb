# encoding: utf-8

# Wire module
module Wire
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
