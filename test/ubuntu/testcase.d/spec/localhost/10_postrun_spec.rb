require 'spec_helper.rb'

describe 'It should end in a clean state' do
	describe command 'sudo /usr/bin/ovs-vsctl list-br | wc -l' do
		it { should return_stdout('0') }
	end
end


