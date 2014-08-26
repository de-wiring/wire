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

    describe file '/etc/dnsmasq.d/wire__<%= zone_name %>.conf' do
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

    # generate template part
    # returns
    # - erb template for spec_helper.rb file
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

    # generate template part
    # returns
    # - erb template for Rakefile
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
end
