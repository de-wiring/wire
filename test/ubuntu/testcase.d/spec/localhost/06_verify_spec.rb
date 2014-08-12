require 'spec_helper.rb'

describe 'It should verify an instantiated model correctly' do
	describe command 'sudo /mnt/project/bin/wire verify /mnt/project/test/d1' do
		it { should return_exit_status 0 }
		its(:stdout) { should match /^OK/ }
		its(:stdout) { should_not match /^ERROR/ }
	end
end

