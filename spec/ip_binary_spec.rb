require 'spec_helper'

include Wire::Resource

describe IPBinary do
  let(:ipb) { IPBinary.new }
  let(:lo_out) { <<EOS
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default
  link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
  inet 127.0.0.1/8 scope host lo
     valid_lft forever preferred_lft forever
  inet6 ::1/128 scope host
     valid_lft forever preferred_lft forever' }
EOS
  }
  let(:lo_link_out) { "link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00" }
  let(:lo_device_out) { "1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default" }
  let(:lo_inet_out) { "inet 127.0.0.1/8 scope host lo" }
  let(:lo_inet_out2) { "inet 192.168.0.1/24 brd 255.255.255.0 scope host ethX:Y" }

  it 'should parse the link line correctly' do
    Object.any_instance.stub(:"`").and_return('')

    result = ipb.get_ipaddr_data_link(lo_link_out)
    result[:type].should eq('loopback')
    result[:mac].should eq('00:00:00:00:00:00')
    result[:brd].should eq('00:00:00:00:00:00')
  end

  it 'should parse the device line correctly' do
    Object.any_instance.stub(:"`").and_return('')

    result = ipb.get_ipaddr_data_device(lo_device_out)
    result[:id].should eq('1')
    result[:device].should eq('lo')
    result[:options].should eq('LOOPBACK,UP,LOWER_UP')
    result[:mtu].should eq('65536')
    result[:state].should eq('UNKNOWN')
    result[:group].should eq('default')
  end

  it 'should parse the inet line correctly' do
    Object.any_instance.stub(:"`").and_return('')

    result = ipb.get_ipaddr_data_inet(lo_inet_out)
    result[:ip].should eq('127.0.0.1')
    result[:cidr].should eq('127.0.0.1/8')
    result[:network].should eq('/8')
    result[:brd].should eq(nil)
    result[:scope].should eq('host')
    result[:device].should eq('lo')
  end

  it 'should construct command correctly' do
    Object.any_instance.stub(:"`").and_return('')

    localexec_stub = double('LocalExecution')
    localexec_stub.stub(:run).and_return(true)
    localexec_stub.stub(:exitstatus).and_return(0)

    LocalExecution.stub(:with).with('/sbin/ip', ['addr','show','lo'], {:b_shell=>false, :b_sudo=>false}).and_yield(localexec_stub)


    lambda {
      ipb.get_ipaddr_data('lo')
    }.should raise_error
  end

  it 'should fail on empty input' do
    Object.any_instance.stub(:"`").and_return('')

    expect(ipb).to receive(:call_addr_show).and_return('')

    lambda {
      ipb.get_ipaddr_data('lo')
    }.should raise_error
  end

  it 'should parse the inet line correctly' do
    Object.any_instance.stub(:"`").and_return('')

    result = ipb.get_ipaddr_data_inet(lo_inet_out2)
    result[:ip].should eq('192.168.0.1')
    result[:cidr].should eq('192.168.0.1/24')
    result[:network].should eq('/24')
    result[:brd].should eq('255.255.255.0')
    result[:scope].should eq('host')
    result[:device].should eq('ethX:Y')
  end

  it 'should return a correct device details on test data' do
    Object.any_instance.stub(:"`").and_return('')

    expect(ipb).to receive(:call_addr_show).and_return(lo_out)

    result = ipb.get_ipaddr_data('lo')
    result[:id].should eq('1')
    result[:device].should eq('lo')
    result[:options].should eq('LOOPBACK,UP,LOWER_UP')
    result[:mtu].should eq('65536')
    result[:state].should eq('UNKNOWN')
    result[:group].should eq('default')
  end

  it 'should return a correct inet details on test data' do
    Object.any_instance.stub(:"`").and_return('')

    expect(ipb).to receive(:call_addr_show).and_return(lo_out)

    result = ipb.get_ipaddr_data('lo')
    result[:inet].should_not eq(nil)
    result[:inet].class.should eq(Hash)

    r = result[:inet]
    r.keys.should eq(['lo'])

    lo = r['lo']
    lo.should_not eq(nil)
    lo[:device].should eq('lo')
    lo[:ip].should eq('127.0.0.1')
    lo[:cidr].should eq('127.0.0.1/8')
    lo[:network].should eq('/8')
    lo[:brd].should eq(nil)
    lo[:scope].should eq('host')
  end

end

