require 'spec_helper.rb'

# 00_prerun
# make sure that we have a clean system with no
# bridges etc otherwise following test cases do not
# make sense

describe 'It should be in a clean state before starting any tests' do
	describe 'There should be no ovs bridges' do
		describe command 'sudo /usr/bin/ovs-vsctl list-br | wc -l' do
			it { should return_stdout('0') }
		end
  end

  describe 'There should be no docker containers around' do
    describe command 'sudo docker ps -q | wc -l' do
      it { should return_stdout('0') }
    end
  end

  describe 'We should have wire installed' do
    describe command 'which wire' do
      its(:exit_status) { should eq 0 }
      it { should return_stdout('/usr/local/bin/wire') }
    end

    describe command 'gem list --local dewiring' do
      its(:stdout) { should match /dewiring/ }
    end
  end
end

