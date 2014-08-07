require 'spec_helper'

include Wire::Resource

describe Resource do

  it 'should construct correctly' do
    (ResourceBase.new('Test')).to_s.should eq('Resource:[Test]')
  end
end
