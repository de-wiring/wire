# encoding: utf-8

# The MIT License (MIT)
# Copyright (c) 2014 Andreas Schmidt, andreas@de-wiring.net
#

# Wire module
module Wire
  # stateless erb template methods used by spec_command.rb
  class SpecTemplates
    # rubocop:disable Lint/UnusedMethodArgument
    # :reek:UnusedParameters
    def self.build_template__bridge_exists
      <<ERB
  describe 'In zone <%= zone_name %> we should have an ovs bridge named <%= bridge_name %>' do
    describe command "sudo ovs-vsctl list-br" do
      its(:stdout) { should match /<%= bridge_name %>/ }
    end
  end
ERB
    end

    # rubocop:disable Lint/UnusedMethodArgument
    # :reek:UnusedParameters
    def self.build_template__bridge_vlan_id_and_trunk
      <<ERB
  describe 'In zone <%= zone_name %>, ovs vlan bridge named <%= bridge_name %> ' \
           'should have id <%= vlanid %>' do
    describe command "sudo ovs-vsctl br-to-vlan <%= bridge_name %>" do
      its(:stdout) { should match /<%= vlanid %>/ }
    end
  end
  describe 'In zone <%= zone_name %>, ovs vlan bridge named <%= bridge_name %> ' \
           'should have parent <%= on_trunk %>' do
    describe command "sudo ovs-vsctl br-to-parent <%= bridge_name %>" do
      its(:stdout) { should match /<%= on_trunk %>/ }
    end
  end
ERB
    end

    # rubocop:disable Lint/UnusedMethodArgument
    # :reek:UnusedParameters
    def self.build_template__ip_is_up
      <<ERB
  describe 'In zone <%= zone_name %> we should have the ip <%= ip %> ' \
           'on ovs bridge named <%= bridge_name %>' do
    describe interface "<%= bridge_name %>" do
      it { should have_ipv4_address '<%= ip %>' }
    end
  end
ERB
    end

    # rubocop:disable Lint/UnusedMethodArgument
    # :reek:UnusedParameters
    # requires zone_name, hostip, bridge_name, ip_start, ip_end
    def self.build_template__dhcp_is_valid
      <<ERB
  describe 'In zone <%= zone_name %> we should have dhcp service on ip <%= hostip %> ' \
           'on ovs bridge named <%= bridge_name %>, serving addresses from ' \
           '<%= ip_start %> to <%= ip_end %>' do

    describe file '/etc/dnsmasq.d/wire__<%= zone_name %>__<%= bridge_name %>.conf' do
      it { should be_file }
      its(:content) { should match /<%= ip_start %>/ }
      its(:content) { should match /<%= ip_end %>/ }
      its(:content) { should match /<%= bridge_name %>/ }
    end

    describe process 'dnsmasq' do
      it { should be_running }
    end

    describe port(67) do
      it { should be_listening.with('udp') }
    end

    describe command '/bin/netstat -nlup' do
      its(:stdout) { should match /67.*dnsmasq/ }
    end
  end
ERB
    end

    # rubocop:disable Lint/UnusedMethodArgument
    # :reek:UnusedParameters
    # requires figfile, appgroup_name
    def self.build_template__fig_file_is_valid
      <<ERB
  describe 'In zone <%= zone_name %> we should have fig model file for '\
           'appgroup <%= appgroup_name %>' do
    describe file '<%= figfile %>' do
      it { should be_file }
    end
  end
ERB
    end

    # rubocop:disable Lint/UnusedMethodArgument
    # :reek:UnusedParameters
    # requires zone_name, figfile, appgroup_name
    def self.build_template__fig_containers_are_up
      <<ERB
  describe 'In zone <%= zone_name %> we should have containers managed '\
           'by fig for appgroup <%= appgroup_name %>' do
    describe command 'sudo fig -p <%= appgroup_name %> -f <%= figfile %> ps' do
      its(:stdout) { should match /Up/ }
    end
  end
ERB
    end

    # generate template part
    # returns
    # - erb template for spec_helper.rb file
    def self.template_spec_helper
      <<ERB
require 'serverspec'

set :backend, :exec
ERB
    end

    # generate template part
    # returns
    # - erb template for Rakefile
    def self.template_rakefile
      <<ERB
require 'rake'
require 'rspec/core/rake_task'

task :spec    => 'spec:all'
task :default => :spec

namespace :spec do
  targets = []
  Dir.glob('./spec/*').each do |dir|
    next unless File.directory?(dir)
    targets << File.basename(dir)
  end

  task :all     => targets
  task :default => :all

  targets.each do |target|
    desc "Run serverspec tests to \#{target}"
    RSpec::Core::RakeTask.new(target.to_sym) do |t|
      ENV['TARGET_HOST'] = target
      t.pattern = "spec/\#{target}/*_spec.rb"
      t.rspec_opts = '--format documentation --color'
    end
  end
end
ERB
    end
  end
end
