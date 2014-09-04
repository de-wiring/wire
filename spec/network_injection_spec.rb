# encoding: utf-8

require 'spec_helper'

describe Wire::Resource::NetworkInjection do
  before(:all) do
    Object.any_instance.stub(:"`").and_return('')
  end

  let(:ni) { Wire::Resource::NetworkInjection.new('TEST',%w(NETWORK_A NETWORK_B), %w(4711 4712 4713)) }
  let(:params) { ['NETWORK_A:NETWORK_A NETWORK_B:NETWORK_B', '4711 4712 4713'] }
  it 'should initialize correctly' do
    ni.to_s.should eq('NetworkInjection:[TEST,containers=4711/4712/4713,' \
        'network_args=NETWORK_A:NETWORK_A NETWORK_B:NETWORK_B]')
  end

  it 'should construct helper params correctly' do
    ni.construct_helper_params.should eq('NETWORK_A:NETWORK_A NETWORK_B:NETWORK_B')
  end

  it 'should call helper with verify action' do
    ni.stub(:with_helper).with('verify', params, '--quiet').and_return(true)
    ni.up?.should eq(true)
  end

  it 'should call helper with attach action' do
    ni.stub(:with_helper).with('attach', params).and_return(true)
    ni.up.should eq(true)
  end

  it 'should call helper with detach action' do
    ni.stub(:with_helper).with('detach', params).and_return(true)
    ni.down.should eq(true)
  end

  it 'should execute helper' do
    localexec_stub = double('LocalExecution')
    localexec_stub.stub(:run).and_return(true)
    localexec_stub.stub(:exitstatus).and_return(0)
    localexec_stub.stub(:stdout).and_return('OK')

    LocalExecution.stub(:with).and_yield(localexec_stub)

    ni.up?.should eq(true)

    localexec_stub = double('LocalExecution')
    localexec_stub.stub(:run).and_return(true)
    localexec_stub.stub(:exitstatus).and_return(0)
    localexec_stub.stub(:stdout).and_return('ERROR')

    LocalExecution.stub(:with).and_yield(localexec_stub)

    ni.up?.should eq(false)


    localexec_stub = double('LocalExecution')
    localexec_stub.stub(:run).and_return(true)
    localexec_stub.stub(:exitstatus).and_return(0)
    localexec_stub.stub(:stdout).and_return('OK')

    LocalExecution.stub(:with).and_yield(localexec_stub)

    ni.up.should eq(true)

    localexec_stub = double('LocalExecution')
    localexec_stub.stub(:run).and_return(true)
    localexec_stub.stub(:exitstatus).and_return(0)
    localexec_stub.stub(:stdout).and_return('ERROR')

    LocalExecution.stub(:with).and_yield(localexec_stub)

    ni.up.should eq(false)

    localexec_stub = double('LocalExecution')
    localexec_stub.stub(:run).and_return(true)
    localexec_stub.stub(:exitstatus).and_return(0)
    localexec_stub.stub(:stdout).and_return('OK')

    LocalExecution.stub(:with).and_yield(localexec_stub)

    ni.down.should eq(true)

    localexec_stub = double('LocalExecution')
    localexec_stub.stub(:run).and_return(true)
    localexec_stub.stub(:exitstatus).and_return(0)
    localexec_stub.stub(:stdout).and_return('ERROR')

    LocalExecution.stub(:with).and_yield(localexec_stub)

    ni.down.should eq(false)

  end
end