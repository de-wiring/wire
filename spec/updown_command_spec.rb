require 'spec_helper.rb'

describe DownCommand do
  let(:project) {
    p = Project.new(".")
    p.merge_element(:zones,
                    { 'z1' => { } }
    )
    p.merge_element(:networks,
                    { 'n1' => { :zone => 'z1', :network => '10.0.0.0/8', :hostip => '10.20.30.1'} }
    )
    p
  }

  it 'Should run on all zones' do
    dc = DownCommand.new
    dc.project = project

    expect(dc).to receive(:run_on_zone).and_return(true)
    dc.run_on_project_zones(%W(z1))

    dc = DownCommand.new
    dc.project = project

    expect(dc).to receive(:handle_bridge).and_return(true)
    expect(dc).to receive(:handle_hostip).and_return(true)
    dc.run_on_project_zones(%W(z1))
  end


  it 'Should leave an already downed model as it is' do

    ovs_bridge_stub = double('OVSBridge')
    ovs_bridge_stub.stub(:down?).and_return(true)
    ovs_bridge_stub.stub(:down).and_return(true)
    hostip_stub = double('IPAddressOnIntf')
    ovs_bridge_stub.stub(:down?).and_return(false)
    hostip_stub.stub(:down?).and_return(true)
    hostip_stub.stub(:down).and_return(true)

    Wire::Resource::ResourceFactory.instance.stub(:create).and_return(ovs_bridge_stub)
    Wire::Resource::ResourceFactory.instance.stub(:create).and_return(hostip_stub)

    out_,err_ = streams_before
    begin
      vc = DownCommand.new
      vc.project = project
      vc.run_on_project
    ensure
      streams_after(out_,err_)
    end
  end


end

describe UpCommand do
  let(:project) {
    p = Project.new(".")
    p.merge_element(:zones,
                    { 'z1' => { } }
    )
    p.merge_element(:networks,
                    { 'n1' => { :zone => 'z1', :network => '10.0.0.0/8', :hostip => '10.20.30.1'} }
    )
    p
  }

  it 'Should run on all zones' do
    dc = UpCommand.new
    dc.project = project

    expect(dc).to receive(:run_on_zone).and_return(true)
    dc.run_on_project_zones(%W(z1))

    dc = UpCommand.new
    dc.project = project

    expect(dc).to receive(:handle_bridge).and_return(true)
    expect(dc).to receive(:handle_hostip).and_return(true)
    dc.run_on_project_zones(%W(z1))
  end

  it 'Should leave an already upped model as it is' do

    ovs_bridge_stub = double('OVSBridge')
    ovs_bridge_stub.stub(:exist?).and_return(true)
    ovs_bridge_stub.stub(:up?).and_return(true)
    hostip_stub = double('IPAddressOnIntf')
    hostip_stub.stub(:exist?).and_return(true)
    hostip_stub.stub(:up?).and_return(true)
    hostip_stub.stub(:up).and_return(true)

    Wire::Resource::ResourceFactory.instance.stub(:create).and_return(ovs_bridge_stub)
    Wire::Resource::ResourceFactory.instance.stub(:create).and_return(hostip_stub)

    out_,err_ = streams_before
    begin
      vc = UpCommand.new
      vc.project = project
      vc.run_on_project
    ensure
      streams_after(out_,err_)
    end
  end


end