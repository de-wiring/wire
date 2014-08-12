require 'spec_helper.rb'

describe 'It should bring a valid model down' do
	describe command 'sudo /mnt/project/bin/wire down /mnt/project/test/d1' do
		it { should return_exit_status 0 }
		its(:stdout) { should match /^.*down/ }
		its(:stdout) { should match /^OK/ }
	end
	describe command 'sudo /mnt/project/bin/wire down /mnt/project/test/d1' do
		it { should return_exit_status 0 }
		its(:stdout) { should match /^.*already down/ }
		its(:stdout) { should match /^OK/ }
	end
end

