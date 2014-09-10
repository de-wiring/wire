require 'spec_helper'

describe BaseCommand do
  it '#ensure_hostip_netmask' do
    network_data = {
        :network => '10.1.0.0/16'
    }
    bc = BaseCommand.new

    bc.ensure_hostip_netmask('10.1.1.1/24', network_data).should eq('10.1.1.1/24')
    bc.ensure_hostip_netmask('10.1.1.1', network_data).should eq('10.1.1.1/16')

    network_data = {
        :network => '10.1.0.0'
    }
    bc.ensure_hostip_netmask('10.1.1.1', network_data).should eq('10.1.1.1')
  end

  it '#default_handle_resource' do
    resource = double('R1')
    resource.stub(:send).with(:up?).and_return(true)
    resource.stub(:name).and_return('noname')

    bc = BaseCommand.new
    bc.stub(:outputs)
    bc.default_handle_resource(resource,:r,'empty',:up)

    resource = double('R2')
    resource.stub(:send).with(:up?).and_return(false)
    resource.stub(:send).with(:up).and_return(true)
    resource.stub(:send).with(:up?).and_return(false)

    bc = BaseCommand.new
    bc.stub(:outputs)
    bc.default_handle_resource(resource,:r,'empty',:up)
  end
end