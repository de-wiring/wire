
require 'spec_helper'

describe 'It should have dnsmasq installed' do
  describe package 'dnsmasq' do
    it { should be_installed }
  end

  describe file '/etc/dnsmasq.d/' do
    it { should be_directory }
  end

  describe process 'dnsmasq' do
    it { should be_running }
  end
end


