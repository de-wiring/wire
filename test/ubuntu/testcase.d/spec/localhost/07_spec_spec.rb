require 'spec_helper.rb'

describe 'It should generate and run serverspec correctly' do
	describe command 'sudo /mnt/project/bin/wire spec /mnt/project/test/d1' do
		it { should return_exit_status 0 }
	end

	%W( serverspec serverspec/spec serverspec/spec/localhost ).each do |d|
		describe file "/mnt/project/test/d1/#{d}" do
			it { should be_directory }
		end
	end
	%W( serverspec/Rakefile serverspec/spec/spec_helper.rb ).each do |d|
		describe file "/mnt/project/test/d1/#{d}" do
			it { should be_file }
		end
	end

	describe command 'sudo /mnt/project/bin/wire spec /mnt/project/test/d1 --run' do
		it { should return_exit_status 0 }
		its(:stdout) { should match /0 failures/ }
	end
end

