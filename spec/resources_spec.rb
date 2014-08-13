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
