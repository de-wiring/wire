require 'spec_helper'

describe VerificationError do

  it 'should display VerificationErrors correctly' do
    error = VerificationError.new 'FooMessage', 'FooType', 'FooObject', Object.new
    error.to_s.should eq('VerificationError on FooType FooObject : FooMessage')
  end
end

describe VerifyCommand do
   it 'should not yield errors on correct sample project' do

     Wire::Resource::ResourceFactory.instance.stub(:create).and_return(OVSBridge_Stub.new(true))

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

     vc.findings.size.should eq(0)
   end

   it 'should yield errors on valid sample project but bad state' do

     Wire::Resource::ResourceFactory.instance.stub(:create).and_return(OVSBridge_Stub.new(false))

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
end


