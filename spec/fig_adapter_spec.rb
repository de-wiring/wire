require 'spec_helper'

describe Wire::Resource::FigAdapter do
  let(:target) {
    o = Wire::Resource::FigAdapter.new('T_E-S_T','/tmp/nonexisting')
    o.executables[:fig] = '/bin/test'
    o
  }

  it 'should mange fig project names' do
    Object.any_instance.stub(:"`").and_return('')

    target.name.should eq('TEST')

  end

  it 'should handle up? correctly' do
    Object.any_instance.stub(:"`").and_return('')

    localexec_stub = double('LocalExecution')
    localexec_stub.stub(:run).and_return(true)
    localexec_stub.stub(:exitstatus).and_return(0)
    localexec_stub.stub(:stdout).and_return('TEST Exit')

    target.stub(:with_fig).and_yield(localexec_stub)

    target.up?.should eq(false)

    # pos.
    localexec_stub = double('LocalExecution')
    localexec_stub.stub(:run).and_return(true)
    localexec_stub.stub(:exitstatus).and_return(0)
    localexec_stub.stub(:stdout).and_return('TEST Up')

    target.stub(:with_fig).and_yield(localexec_stub)

    target.up?.should eq(true)
  end

  it 'should return container ids from fig output ' do
    Object.any_instance.stub(:"`").and_return('')

    localexec_stub = double('LocalExecution')
    localexec_stub.stub(:run).and_return(true)
    localexec_stub.stub(:exitstatus).and_return(0)
    localexec_stub.stub(:stdout).and_return("TESTTESTID1\nTESTTESTID2")

    target.stub(:with_fig).and_yield(localexec_stub)

    target.up_ids.should eq(['TESTTESTID1','TESTTESTID2'])

  end

  it 'should handle up correctly' do
    Object.any_instance.stub(:"`").and_return('')

    localexec_stub = double('LocalExecution')
    localexec_stub.stub(:run).and_return(true)
    localexec_stub.stub(:exitstatus).and_return(0)

    target.stub(:with_fig).and_yield(localexec_stub)

    target.up.should eq(true)
  end

  it 'should handle down correctly' do
    Object.any_instance.stub(:"`").and_return('')

    localexec_stub = double('LocalExecution')
    localexec_stub.stub(:run).and_return(true)
    localexec_stub.stub(:exitstatus).and_return(0)

    target.stub(:with_fig).and_yield(localexec_stub)

    target.down.should eq(true)
  end


  it 'should handle up correctly' do
    Object.any_instance.stub(:"`").and_return('')

    localexec_stub = double('LocalExecution')
    localexec_stub.stub(:run).and_return(true)
    localexec_stub.stub(:exitstatus).and_return(0)

    target.stub(:with_fig).and_yield(localexec_stub)

    target.down.should eq(true)
  end
end