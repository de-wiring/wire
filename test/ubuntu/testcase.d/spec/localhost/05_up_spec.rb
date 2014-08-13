require 'spec_helper.rb'

# 05_up
# make sure we are able to start model elements
# on clean system and also on system with existing
# model elements
# tests 
# - wire up

describe 'It should be able to instantiate a valid model with no errors' do
	describe command "sudo #{property[:wire_executable]} up #{property[:model_path]}" do
		it { should return_exit_status 0 }
		its(:stdout) { should match /^.*up/ }
		its(:stdout) { should match /^OK/ }
	end
end

describe 'It should be able to instantiate a valid model with no errors even if it is already running' do
	describe command "sudo #{property[:wire_executable]} up #{property[:model_path]}" do
		it { should return_exit_status 0 }
		its(:stdout) { should match /^.*already up/ }
		its(:stdout) { should match /^OK/ }
	end
end

