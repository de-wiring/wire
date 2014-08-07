require 'spec_helper'

include Wire
include Wire::Resource

class LocalExecutionMock < Wire::Execution::LocalExecution
  def initialize(command, args = nil, options = {})
    super(command, args, options)
  end
  def construct_command
    puts 'Da!'
  end
end

describe OVSBridge do
  before {
    LocalExecution.any_instance.should_receive(:with).and_return(LocalExecutionMock.new('/bin/true'))
  }
#  it 'should run ovs-vsctl when asking if exists' do
    #b = OVSBridge.new('nonexisting_bridge')
    #b.exist?.should eq(false)
#  end

end
