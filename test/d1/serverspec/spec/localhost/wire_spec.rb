require 'spec_helper.rb'

# begin of generated specs

  describe 'In zone dmz we should have an ovs bridge named dmz-int' do
    describe command "sudo ovs-vsctl list-br" do
      its(:stdout) { should match /dmz-int/ }
    end
  end

  describe 'In zone dmz we should have the ip 192.168.10.1 '            'on ovs bridge named dmz-int' do
    describe interface "dmz-int" do
      it { should have_ipv4_address '192.168.10.1' }
    end
  end

  describe 'In zone dmz we should have dhcp service on ip 192.168.10.1 '            'on ovs bridge named dmz-int, serving addresses from 192.168.10.10 to 192.168.10.50' do

    describe file '/etc/dnsmasq.d/wire__dmz.conf' do
      it { should be_file }
      its(:content) { should match /192.168.10.10/ }
      its(:content) { should match /192.168.10.50/ }
      its(:content) { should match /dmz-int/ }
    end

    describe process 'dnsmasq' do
      it { should be_running }
    end

    describe port(67) do
      it { should be_listening.with('udp') }
    end

    describe command '/bin/netstat -nlup' do
      its(:stdout) { should match /67.*dnsmasq/ }
    end
  end

  describe 'In zone dmz we should have an ovs bridge named dmz-ext' do
    describe command "sudo ovs-vsctl list-br" do
      its(:stdout) { should match /dmz-ext/ }
    end
  end

  describe 'In zone backend we should have an ovs bridge named backend-int' do
    describe command "sudo ovs-vsctl list-br" do
      its(:stdout) { should match /backend-int/ }
    end
  end

  describe 'In zone backend we should have the ip 192.168.30.1 '            'on ovs bridge named backend-int' do
    describe interface "backend-int" do
      it { should have_ipv4_address '192.168.30.1' }
    end
  end


# end of spec file
