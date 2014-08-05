require 'spec_helper.rb'

# begin of generated specs

  describe 'In zone dmz we should have an ovs bridge named dmz-int' do
    describe command "sudo ovs-vsctl list-br" do
      its(:stdout) { should match /dmz-int/ }
    end
  end

  describe 'In zone dmz we should have an ovs bridge named dmz-ext' do
    describe command "sudo ovs-vsctl list-br" do
      its(:stdout) { should match /dmz-ext/ }
    end
  end


# end of spec file
