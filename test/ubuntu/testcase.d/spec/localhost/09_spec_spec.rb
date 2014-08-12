require 'spec_helper.rb'

describe 'It should run serverspec with failures' do
	describe command 'sudo /mnt/project/bin/wire spec /mnt/project/test/d1 --run' do
		it { should return_exit_status 0 }
		its(:stdout) { should_not match /0 failures/ }
	end
end

