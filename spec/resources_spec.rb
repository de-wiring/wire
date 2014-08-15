require 'spec_helper'

include Wire::Resource

describe Resource do
  it 'should construct correctly' do
    (ResourceBase.new('Test')).to_s.should eq('Resource:[Test]')
  end
end

describe ResourceFactory do
  it 'should be able to create an ovs bridge' do
    x = ResourceFactory.instance.create(:ovsbridge,'testbridge')
    x.class.should eq(OVSBridge)
    x.name.should eq('testbridge')
  end

  it 'should fail to create an unknown resource' do
    lambda {
      ResourceFactory.instance.create(:unknown,'totally')
    }.should raise_error
  end
end

describe IPAddr do
  let(:ip1) { IPAddr.new('192.168.10.0/24') }
  let(:ip2) { IPAddr.new('192.168.10.2') }
  let(:ip3) { IPAddr.new('192.168.20.2') }

  it '#in_range_of?' do
    ip2.in_range_of?(ip1).should eq(true)
    ip3.in_range_of?(ip1).should eq(false)
  end
end