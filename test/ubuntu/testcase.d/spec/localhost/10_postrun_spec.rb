require 'spec_helper.rb'

# 10_postrun
# after running the test suite, we have to end
# with a clean system
# 
describe 'It should end in a clean state' do
	describe 'There should be no bridges left' do
		describe command 'sudo /usr/bin/ovs-vsctl list-br | wc -l' do
			it { should return_stdout('0') }
		end
	end

  describe 'There should be no docker containers around' do
    describe command 'sudo docker ps -q | wc -l' do
      it { should return_stdout('0') }
    end
  end

  # TODO: There should be no veth interfaces around

end


