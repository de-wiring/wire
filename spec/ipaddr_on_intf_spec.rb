require 'spec_helper'

include Wire
include Wire::Resource


describe IPAddressOnIntf do
  it 'should construct the exists? command correctly' do
    obj = IPAddressOnIntf.new('127.0.0.1/32', 'lo37')
    obj.construct_exist_command.should eq('/sbin/ip addr show lo37 | grep -wq -E "^\W*inet 127.0.0.1/32.*lo37"')
  end

  it 'should construct the add command correctly' do
    obj = IPAddressOnIntf.new('127.0.0.1/32', 'lo37')
    obj.construct_add_command.should eq('/sbin/ip addr add 127.0.0.1/32 dev lo37')
  end

  it 'should construct the delete command correctly' do
    obj = IPAddressOnIntf.new('127.0.0.1', 'lo37')
    obj.construct_delete_command.should eq('/sbin/ip addr del 127.0.0.1/32 dev lo37')
  end

  it 'should fail on missing params' do
    lambda {
      IPAddressOnIntf.new('127.0.0.1', '')
    }.should raise_error

    lambda {
      IPAddressOnIntf.new('', 'lo37')
    }.should raise_error

    lambda {
      IPAddressOnIntf.new('', nil)
    }.should raise_error

  end
end

