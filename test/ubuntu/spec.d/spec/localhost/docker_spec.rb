require 'spec_helper'

describe 'It should have docker installed' do
	describe package 'lxc-docker' do
		it { should be_installed }
	end

	describe group 'docker' do
		it { should exist }
	end

	describe file '/var/run/docker.sock' do
		it { should be_socket }
		it { should be_owned_by 'root' }
		it { should be_grouped_into 'docker' }
	end

	describe command 'docker -v' do
		its(:stdout) { should match '^Docker version 1\.3.*' }
 	end
end

describe 'Docker should be running' do
	describe service 'docker' do
		it { should be_running }
	end

	describe process 'docker' do
		it { should be_running }
	end
end

