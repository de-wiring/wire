require 'spec_helper.rb'


describe UpCommand do
  before(:all) do
    Object.any_instance.stub(:"`").and_return('')
  end

  let(:project) {
    p = Project.new(".")
    p.merge_element(:zones,
                    { 'z1' => { } }
    )
    p.merge_element(:networks,
                    { 'n1' => { :zone => 'z1', :network => '10.0.0.0/8', :hostip => '10.20.30.1',
                                :dhcp => { :start => '10.20.30.10', :end => '10.20.30.20' } } }
    )
    p
  }
  let(:project_appgroup) {
    p = Project.new(".")
    p.merge_element(:zones,
                    { 'z1' => { } }
    )
    p.merge_element(:networks,
                    { 'n1' => { :zone => 'z1', :network => '10.0.0.0/8', :hostip => '10.20.30.1',
                                :dhcp => { :start => '10.20.30.10', :end => '10.20.30.20' } } }
    )
    p.merge_element(:appgroups,
                     { 'g1' => { :zone => 'z1', :controller => { :type => 'fig', :file => '/tmp/fig.yml'}} }
    )
    p
  }
  let(:project_appgroup_wrong_controller) {
    p = Project.new(".")
    p.merge_element(:zones,
                    { 'z1' => { } }
    )
    p.merge_element(:networks,
                    { 'n1' => { :zone => 'z1', :network => '10.0.0.0/8', :hostip => '10.20.30.1',
                                :dhcp => { :start => '10.20.30.10', :end => '10.20.30.20' } } }
    )
    p.merge_element(:appgroups,
                     { 'g1' => { :zone => 'z1', :controller => { :type => 'NONEXISTING'}} }
    )
    p
  }

  it 'Should run on all zones' do
    dc = UpCommand.new
    dc.project = project_appgroup

    expect(dc).to receive(:run_on_zone).and_return(true)
    dc.run_on_project_zones(%W(z1))

    dc = UpCommand.new
    dc.project = project_appgroup

    dch = dc.handler

    expect(dch).to receive(:handle_bridge).and_return(true)
    expect(dch).to receive(:handle_hostip).and_return(true)
    expect(dch).to receive(:handle_dhcp).and_return(true)
    expect(dch).to receive(:handle_appgroup).and_return(true)
    expect(dch).to receive(:handle_network_attachments).and_return(true)

    dc.run_on_project_zones(%W(z1))

    dc = UpCommand.new
    dc.project = project_appgroup

    dch = dc.handler

    expect(dch).to receive(:handle_bridge).and_return(true)
    expect(dch).to receive(:handle_hostip).and_return(true)
    expect(dch).to receive(:handle_dhcp).and_return(true)
    expect(dch).to receive(:handle_appgroup__fig).and_return(true)
    expect(dch).to receive(:handle_network_attachments).and_return(true)

    dc.run_on_project_zones(%W(z1))
  end

  it 'should fail on appgroup with nonexisting controller type' do
    dc = UpCommand.new
    dc.project = project_appgroup_wrong_controller

    dch = dc.handler

    expect(dch).to receive(:handle_bridge).and_return(true)
    expect(dch).to receive(:handle_hostip).and_return(true)
    expect(dch).to receive(:handle_dhcp).and_return(true)
    expect(dch).to receive(:handle_network_attachments).and_return(true)

    dc.run_on_project_zones(%W(z1))
  end

  it 'Should leave an already upped model as it is' do
    ovs_bridge_stub = double('OVSBridge')
    ovs_bridge_stub.stub(:exist?).and_return(true)
    ovs_bridge_stub.stub(:up?).and_return(true)
    ovs_bridge_stub.stub(:name).and_return('Namedummy')
    hostip_stub = double('IPAddressOnIntf')
    hostip_stub.stub(:exist?).and_return(true)
    hostip_stub.stub(:up?).and_return(true)
    hostip_stub.stub(:up).and_return(true)
    hostip_stub.stub(:name).and_return('Namedummy')

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

  it 'should use the FigAdapter resource' do

    ovs_bridge_stub = double('OVSBridge')
    ovs_bridge_stub.stub(:exist?).and_return(true)
    ovs_bridge_stub.stub(:up?).and_return(true)
    ovs_bridge_stub.stub(:up).and_return(true)
    hostip_stub = double('IPAddressOnIntf')
    hostip_stub.stub(:exist?).and_return(true)
    hostip_stub.stub(:up?).and_return(false)
    hostip_stub.stub(:up).and_return(true)
    figadapter_stub = double('FigAdapter')
    figadapter_stub.stub(:name).and_return('Namedummy')
    figadapter_stub.stub(:exist?).and_return(true)
    figadapter_stub.stub(:up?).and_return(true)
    figadapter_stub.stub(:up).and_return(true)
    figadapter_stub.stub(:up_ids).and_return([])

    Wire::Resource::ResourceFactory.instance.stub(:create).and_return(ovs_bridge_stub)
    Wire::Resource::ResourceFactory.instance.stub(:create).and_return(hostip_stub)
    Wire::Resource::ResourceFactory.instance.stub(:create).and_return(figadapter_stub)

    out_,err_ = streams_before
    begin
      vc = UpCommand.new
      vc.project = project_appgroup
      vc.run_on_project
    ensure
      streams_after(out_,err_)
    end
  end


  it 'Should bring up a bridge' do

    ovs_bridge_stub = double('OVSBridge')
    ovs_bridge_stub.stub(:up?).and_return(false)
    ovs_bridge_stub.stub(:up)

    Wire::Resource::ResourceFactory.instance.stub(:create).and_return(ovs_bridge_stub)

    out_,err_ = streams_before
    begin
      vc = UpCommand.new
      vc.project = project
      vc.run_on_project
    ensure
      streams_after(out_,err_)
    end
  end

  it 'Should bring up a hostip if bridge is up' do
    ovs_bridge_stub = double('OVSBridge')

    hostip_stub = double('IPAddressOnIntf')
    hostip_stub.stub(:up?).and_return(false)
    hostip_stub.stub(:up).and_return(true)

    Wire::Resource::ResourceFactory.instance.stub(:create).and_return(ovs_bridge_stub)
    Wire::Resource::ResourceFactory.instance.stub(:create).and_return(hostip_stub)

    out_,err_ = streams_before
    begin
      vc = UpCommand.new
      vc.stub(:handle_bridge).and_return(true)
      vc.project = project
      vc.run_on_project
    ensure
      streams_after(out_,err_)
    end
  end

end