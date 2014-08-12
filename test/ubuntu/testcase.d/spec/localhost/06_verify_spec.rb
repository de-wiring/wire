require 'spec_helper.rb'

# 06_verify
# after we instantiated a valid model, make sure 
# that verify runs with no errors
# tests
# - wire verify

describe 'It should verify an instantiated model correctly' do
	describe command 'sudo /mnt/project/bin/wire verify /mnt/project/test/d1' do
		it { should return_exit_status 0 }
		its(:stdout) { should match /^OK/ }
		its(:stdout) { should_not match /^ERROR/ }
	end
end

