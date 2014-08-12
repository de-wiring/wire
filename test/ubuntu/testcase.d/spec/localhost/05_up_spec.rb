require 'spec_helper.rb'

describe 'It should instantiate a valid model' do
	describe command 'sudo /mnt/project/bin/wire up /mnt/project/test/d1' do
		it { should return_exit_status 0 }
		its(:stdout) { should match /^.*up/ }
		its(:stdout) { should match /^OK/ }
	end
	describe command 'sudo /mnt/project/bin/wire up /mnt/project/test/d1' do
		it { should return_exit_status 0 }
		its(:stdout) { should match /^.*already up/ }
		its(:stdout) { should match /^OK/ }
	end
end

