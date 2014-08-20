require 'spec_helper'

include Wire
include Wire::Resource

describe OVSBridge do
  it 'should run ovs-vsctl when asking if bridge is up' do
    localexec_stub = double('LocalExecution')
    localexec_stub.stub(:run).and_return(true)
    localexec_stub.stub(:exitstatus).and_return(2)

    LocalExecution.stub(:with).and_yield(localexec_stub)

    b = OVSBridge.new('nonexisting_bridge')
    b.up?.should eq(false)
  end

  it 'should run ovs-vsctl when asking if bridge is down' do
    localexec_stub = double('LocalExecution')
    localexec_stub.stub(:run).and_return(true)
    localexec_stub.stub(:exitstatus).and_return(2)

    LocalExecution.stub(:with).and_yield(localexec_stub)

    b = OVSBridge.new('nonexisting_bridge')
    b.down?.should eq(true)
  end

  it 'should run ovs-vsctl to bring bridge up' do
    localexec_stub = double('LocalExecution')
    localexec_stub.stub(:run).and_return(true)
    localexec_stub.stub(:exitstatus).and_return(0)

    LocalExecution.stub(:with).and_yield(localexec_stub)

    b = OVSBridge.new('nonexisting_bridge')
    b.up
    b.up?.should eq(true)
  end

  it 'should run ovs-vsctl to bring bridge down' do
    localexec_stub = double('LocalExecution')
    localexec_stub.stub(:run).and_return(true)
    localexec_stub.stub(:exitstatus).and_return(0)

    LocalExecution.stub(:with).and_yield(localexec_stub)

    b = OVSBridge.new('nonexisting_bridge')
    b.down
    b.down?.should eq(false)
  end

end
