require 'spec_helper'

include Wire
include Wire::Resource


describe IPAddressOnIntf do
  it 'should construct the exists? command correctly' do
    obj = IPAddressOnIntf.new('127.0.0.1/32', 'lo37')
    obj.construct_exist_command.should eq('/sbin/ip addr show lo37 | grep -wq -E "^\W*inet 127.0.0.1/32.*lo37"')
  end
end
