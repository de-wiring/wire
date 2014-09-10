require 'spec_helper'

describe VerificationError do
  before(:all) do
    Object.any_instance.stub(:"`").and_return('')
  end


  it 'should display VerificationErrors correctly' do
    error = VerificationError.new 'FooMessage', 'FooType', 'FooObject', Object.new
    error.to_s.should eq('VerificationError on FooType FooObject: FooMessage')
  end
end

describe VerifyCommand do
  before(:all) do
    Object.any_instance.stub(:"`").and_return('')
  end

  it 'should not yield errors on correct sample project' do

     ovs_bridge_stub = double('OVSBridge')
     ovs_bridge_stub.stub(:up?).and_return(true)
     hostip_stub = double('IPAddressOnIntf')
     hostip_stub.stub(:up?).and_return(true)
     figadapter_stub = double('FigAdapter')
     figadapter_stub.stub(:exist?).and_return(true)
     figadapter_stub.stub(:up?).and_return(true)
     figadapter_stub.stub(:up).and_return(true)
     figadapter_stub.stub(:name).and_return('FigAdapterTest')
     figadapter_stub.stub(:up_ids).and_return(%w(1 2 3 4))

     Wire::Resource::ResourceFactory.instance.stub(:create).and_return(ovs_bridge_stub)
     Wire::Resource::ResourceFactory.instance.stub(:create).and_return(hostip_stub)
     Wire::Resource::ResourceFactory.instance.stub(:create).and_return(figadapter_stub)

     p = Project.new('./spec/data')
     p.merge_element(:zones,
                     { 'z1' => { } }
     )
     p.merge_element(:networks,
                     { 'n1' => { :zone => 'z1', :network => '10.0.0.0/8', :hostip => '10.10.20.1', :dhcp => {}} }
     )
     p.merge_element(:appgroups,
                     { 'g1' => { :zone => 'z1', :controller => { :type => 'fig', :file => '/tmp/fig.yml'}} }
     )

     out_,err_ = streams_before
     begin
       vc = VerifyCommand.new
       vc.project = p

       #vc.stub(:handle_appgroup).and_return(true)
       #vc.stub(:handle_dhcp).and_return(true)
       vc.run_on_project
     ensure
       streams_after(out_,err_)
     end

     vc.findings.size.should eq(0)
   end

   it 'should yield errors on valid sample project but bad state' do

     ovs_bridge_stub = double('OVSBridge')
     ovs_bridge_stub.stub(:name).and_return('namedummy')
     ovs_bridge_stub.stub(:up?).and_return(false)
     hostip_stub = double('IPAddressOnIntf')
     hostip_stub.stub(:up?).and_return(false)

     Wire::Resource::ResourceFactory.instance.stub(:create).and_return(ovs_bridge_stub)

     p = Project.new('./spec/data')
     p.merge_element(:zones,
                     { 'z1' => { } }
     )
     p.merge_element(:networks,
                     { 'n1' => { :zone => 'z1'} }
     )

     out_,err_ = streams_before
     begin
       vc = VerifyCommand.new
       vc.project = p
       vc.run_on_project
     ensure
       streams_after(out_,err_)
     end

     vc.findings.size.should eq(2)


   end

   it 'should yield errors on valid sample project but bad state (2)' do

     ovs_bridge_stub = double('OVSBridge')
     ovs_bridge_stub.stub(:up?).and_return(true)
     ovs_bridge_stub.stub(:name).and_return('namedummy')
     hostip_stub = double('IPAddressOnIntf')
     hostip_stub.stub(:exist?).and_return(false)
     hostip_stub.stub(:up?).and_return(false)
     hostip_stub.stub(:up).and_return(true)

     Wire::Resource::ResourceFactory.instance.stub(:create).and_return(ovs_bridge_stub)

     p = Project.new('./spec/data')
     p.merge_element(:zones,
                     { 'z1' => { } }
     )
     p.merge_element(:networks,
                     { 'n1' => { :zone => 'z1', :network => '10.0.0.0/8', :hostip => '10.10.20.1'}  }
     )

     out_,err_ = streams_before
     begin
       vc = VerifyCommand.new
       vc.project = p
       vc.run_on_project
     ensure
       streams_after(out_,err_)
     end

     vc.findings.size.should eq(0)
   end
end


