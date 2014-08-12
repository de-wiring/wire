require 'spec_helper.rb'

# 07_spec
# Since verify has run correctly, we should be able
# to write out the serverspec sources and run
# them without errors
# tests
# - wire spec
# - wire spec --run

describe 'It should generate serverspec correctly' do
	describe command 'sudo /mnt/project/bin/wire spec /mnt/project/test/d1 --run' do
		it { should return_exit_status 0 }
		its(:stdout) { should match /0 failures/ }
	end
end

describe 'It should run serverspec on an upped model without failures' do
	describe command 'sudo /mnt/project/bin/wire spec /mnt/project/test/d1 --run' do
		it { should return_exit_status 0 }
		its(:stdout) { should match /0 failures/ }
	end
end

