require 'spec_helper'

describe Wire::Resource::DHCPRangeConfiguration do
  let(:target) {
    o = Wire::Resource::DHCPRangeConfiguration.new('TEST','NETWORK',{},'10.1.1.10','10.1.1.20')
    o.executables[:service] = '/bin/test'
    o
  }

  it 'should create a valid config file name' do
    Object.any_instance.stub(:"`").and_return('')

    target.create_dnsmaqs_config_filename.should eq('/etc/dnsmasq.d/TEST__NETWORK.conf')
  end

  it 'should check if file exists' do
    Object.any_instance.stub(:"`").and_return('')

    expect(File).to receive(:exist?).and_return(true)
    expect(File).to receive(:readable?).and_return(true)
    expect(File).to receive(:file?).and_return(true)

    target.exist?.should eq(true)

    expect(File).to receive(:exist?).and_return(true)
    expect(File).to receive(:readable?).and_return(false)

    target.exist?.should eq(false)
  end

  it 'should execute a command when asked for up?' do
    Object.any_instance.stub(:"`").and_return('')

    expect(target).to receive(:exist?).and_return(true)
    expect(target).to receive(:create_dnsmaqs_config_filename).and_return('/tmp/nonexisting')
    #expect(Kernel).to receive(:exec).and_return(0)
    target.up?
  end

  it 'should handle up correctly' do
    Object.any_instance.stub(:"`").and_return('')

    expect(target).to receive(:create_dnsmaqs_config_filename).and_return('/tmp/nonexisting')

    localexec_stub = double('LocalExecution')
    localexec_stub.stub(:run).and_return(true)
    localexec_stub.stub(:exitstatus).and_return(2)

    expect(File).to receive(:open).and_return(STDERR)

    LocalExecution.stub(:with).and_yield(localexec_stub)

    target.up
  end

  it 'should handle down correctly' do
    Object.any_instance.stub(:"`").and_return('')

    expect(target).to receive(:create_dnsmaqs_config_filename).and_return('/tmp/nonexisting')

    localexec_stub = double('LocalExecution')
    localexec_stub.stub(:run).and_return(true)
    localexec_stub.stub(:exitstatus).and_return(2)

    expect(File).to receive(:exist?).and_return(true)
    expect(File).to receive(:readable?).and_return(true)
    expect(File).to receive(:file?).and_return(true)

    LocalExecution.stub(:with).and_yield(localexec_stub)

    target.down
  end
end