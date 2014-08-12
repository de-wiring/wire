require 'spec_helper.rb'

# 01_prerun
# make sure that our model definition is there
# and valid.
# tests
# - wire validate

describe 'It should have a valid model' do
	describe file '/mnt/project/test/d1/zones.yaml' do
		it { should be_file }
	end
	describe file '/mnt/project/test/d1/networks.yaml' do
		it { should be_file }
	end

	describe command '/mnt/project/bin/wire validate /mnt/project/test/d1' do
		it { should return_exit_status 0 }
		its(:stdout) { should match /^OK/ }
	end
end

