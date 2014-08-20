require 'spec_helper.rb'

# 01_prerun
# make sure that our model definition is there
# and valid.
# tests
# - wire validate

describe 'It should have a valid model' do
	describe file "#{property[:model_path]}/zones.yaml" do
		it { should be_file }
	end
	describe file "#{property[:model_path]}/networks.yaml" do
		it { should be_file }
	end

	describe command "#{property[:wire_executable]} validate #{property[:model_path]}" do
		it { should return_exit_status 0 }
		its(:stdout) { should match /OK, model is consistent/ }
	end
end

