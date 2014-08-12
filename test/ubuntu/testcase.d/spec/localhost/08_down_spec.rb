require 'spec_helper.rb'

# 08_down
# Make sure we're able to bring existing model elements
# down
# tests
# - wire down

describe 'It should be able to bring a running model down' do
	describe command 'sudo /mnt/project/bin/wire down /mnt/project/test/d1' do
		it { should return_exit_status 0 }
		its(:stdout) { should match /^.*down/ }
		its(:stdout) { should match /^OK/ }
	end
end

describe 'It should down a model thats already down with no errors' do
	describe command 'sudo /mnt/project/bin/wire down /mnt/project/test/d1' do
		it { should return_exit_status 0 }
		its(:stdout) { should match /^.*already down/ }
		its(:stdout) { should match /^OK/ }
	end
end

