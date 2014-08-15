require 'spec_helper'

describe VerificationError do

  it 'should display VerificationErrors correctly' do
    error = VerificationError.new 'FooMessage', 'FooType', 'FooObject', Object.new
    error.to_s.should eq('VerificationError on FooType FooObject : FooMessage')
  end
end

describe VerifyCommand do
   it 'should not yield errors on correct sample project' do

     ovs_bridge_stub = double('OVSBridge')
     ovs_bridge_stub.stub(:exist?).and_return(true)
     hostip_stub = double('IPAddressOnIntf')
     hostip_stub.stub(:exist?).and_return(true)
     hostip_stub.stub(:up?).and_return(true)

     Wire::Resource::ResourceFactory.instance.stub(:create).and_return(ovs_bridge_stub)
     Wire::Resource::ResourceFactory.instance.stub(:create).and_return(hostip_stub)

     p = Project.new('./spec/data')
     p.merge_element(:zones,
                     { 'z1' => { } }
     )
     p.merge_element(:networks,
                     { 'n1' => { :zone => 'z1', :network => '10.0.0.0/8', :hostip => '10.10.20.1'} }
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

   it 'should yield errors on valid sample project but bad state' do

     ovs_bridge_stub = double('OVSBridge')
     ovs_bridge_stub.stub(:exist?).and_return(false)
     hostip_stub = double('IPAddressOnIntf')
     hostip_stub.stub(:exist?).and_return(false)
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
     ovs_bridge_stub.stub(:exist?).and_return(true)
     ovs_bridge_stub.stub(:up?).and_return(true)
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


