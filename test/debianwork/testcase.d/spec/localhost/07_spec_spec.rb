require 'spec_helper.rb'

# 07_spec
# Since verify has run correctly, we should be able
# to write out the serverspec sources and run
# them without errors
# tests
# - wire spec
# - wire spec --run

describe 'It should generate serverspec correctly' do
	describe command "sudo #{property[:wire_executable]} spec #{property[:model_path]}" do
		it { should return_exit_status 0 }
	end

        %W( serverspec serverspec/spec serverspec/spec/localhost ).each do |d|
                describe file "#{property[:model_path]}/#{d}" do
                        it { should be_directory }
                end
        end
        %W( serverspec/Rakefile serverspec/spec/spec_helper.rb ).each do |d|
                describe file "#{property[:model_path]}/#{d}" do
                       it { should be_file }
                end
        end
end

describe 'It should run serverspec on an upped model without failures' do
	describe command "sudo #{property[:wire_executable]} spec #{property[:model_path]} --run" do
		it { should return_exit_status 0 }
		its(:stdout) { should match /0 failures/ }
	end
end

