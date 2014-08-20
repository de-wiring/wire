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
