require 'spec_helper.rb'

# 09_spec
# Since we brought the model elements down, a serverspec
# run has to yield errors, it may not run error-free
# tests
# - wire spec --run

describe 'It should run serverspec on a downed model with failures' do
	describe command "sudo #{property[:wire_executable]} spec #{property[:model_path]} --run" do
		it { should return_exit_status 0 }
		its(:stdout) { should_not match /0 failures/ }
	end
end

