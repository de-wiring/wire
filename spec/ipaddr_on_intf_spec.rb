require 'spec_helper'

include Wire
include Wire::Resource


describe IPAddressOnIntf do
  before(:all) do
    Object.any_instance.stub(:"`").and_return('')
  end

  it 'should construct the exists? command correctly' do
    obj = IPAddressOnIntf.new('127.0.0.1/32', 'lo37')
    cmd_match = '/sbin/ip addr show lo37 | grep -wq -E "^\W*inet 127.0.0.1/32.*lo37"'
    obj.construct_exist_command.should eq(cmd_match)

    localexec_stub = double('LocalExecution')
    localexec_stub.stub(:run).and_return(true)
    localexec_stub.stub(:exitstatus).and_return(0)

    LocalExecution.stub(:with).with(cmd_match, [], {:b_shell=>false, :b_sudo=>false}).and_yield(localexec_stub)


    obj.exist?.should eq(true)
    obj.up?.should eq(true)
    obj.down?.should eq(false)
  end

  it 'should construct the add command correctly' do
    obj = IPAddressOnIntf.new('127.0.0.1/32', 'lo37')
    cmd_match = '/sbin/ip addr add 127.0.0.1/32 dev lo37'
    obj.construct_add_command.should eq(cmd_match)


    localexec_stub = double('LocalExecution')
    localexec_stub.stub(:run).and_return(true)
    localexec_stub.stub(:exitstatus).and_return(0)

    LocalExecution.stub(:with).with(cmd_match, [], {:b_shell=>false, :b_sudo=>true}).and_yield(localexec_stub)

    obj.up.should eq(true)
  end

  it 'should construct the delete command correctly' do
    obj = IPAddressOnIntf.new('127.0.0.1/32', 'lo37')
    cmd_match = '/sbin/ip addr del 127.0.0.1/32 dev lo37'
    obj.construct_delete_command.should eq(cmd_match)

    localexec_stub = double('LocalExecution')
    localexec_stub.stub(:run).and_return(true)
    localexec_stub.stub(:exitstatus).and_return(0)

    LocalExecution.stub(:with).with(cmd_match, [], {:b_shell=>false, :b_sudo=>true}).and_yield(localexec_stub)

    obj.down.should eq(true)
    obj.to_s.should eq('IPAddressOnIntf:[127.0.0.1/32,device=lo37]')
  end

  it 'should fail on missing params' do
    lambda {
      IPAddressOnIntf.new('127.0.0.1', '')
    }.should raise_error

    lambda {
      IPAddressOnIntf.new('', 'lo37')
    }.should raise_error

    lambda {
      IPAddressOnIntf.new('', nil)
    }.should raise_error

  end
end

describe IPAddr do
  before(:all) do
    Object.any_instance.stub(:"`").and_return('')
  end

  let(:ip) { IPAddr.new('10.1.0.0/16') }
  it 'should answer in_range_of? correctly' do
    %w(10.1.0.1/32  10.1.10.0/24 10.1.10.10/32).each do |a|
      IPAddr.new(a).in_range_of?(ip).should eq(true)
    end

    %w(10.2.0.1/32  192.168.1.10/32 8.8.8.8/32 0.0.0.0/0).each do |a|
      IPAddr.new(a).in_range_of?(ip).should eq(false)
    end
  end

  it 'should compute netmasks' do
    ip.netmask.should eq('255.255.0.0')
  end
end