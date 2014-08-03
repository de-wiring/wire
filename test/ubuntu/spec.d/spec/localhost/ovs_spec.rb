
require 'spec_helper'

describe 'It should have open vswitch installed' do

  %W( openvswitch-common openvswitch-switch openvswitch-test ).each do |pkg|
    describe package pkg do
      it { should be_installed}
    end
  end

end


