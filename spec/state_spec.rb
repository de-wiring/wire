require 'spec_helper'

describe StateEntry do
  it 'should produce string representations' do
    s = StateEntry.new(:test,'TEST',:up)
    s.to_pretty_s.should eq('test:TEST is up')
  end

end

describe State do
  it 'should produce string representations' do
    s = State.instance
    s.clean
    s.update(:test,'TEST',:up)
    s.update(:test2,'TEST2',:down)
    s.to_pretty_s.should eq('test:TEST is up,test2:TEST2 is down')
  end

  it 'should update state' do
    s = State.instance
    s.clean

    s.state.size.should eq(0)
    s.state?(:test,'TEST').should eq(false)

    s.update(:test,'TEST',:up)
    s.state.size.should eq(1)

    s.state?(:test,'TEST').should eq(true)

    s.update(:test,'TEST2',:up)
    s.state.size.should eq(2)

    s.update(:test,'TEST2',:down)
    s.state.size.should eq(2)

    s.up?(:test,'TEST').should eq(true)
    s.up?(:test,'NONEX').should eq(false)
    s.down?(:test,'TEST2').should eq(true)
    s.down?(:test,'NONEX').should eq(false)

  end

  it 'should handle changed? correctly' do
    s = State.instance
    s.clean
    s.project = Object.new
    s.project.stub(:target_dir).and_return('/tmp')

    s.changed?.should eq(false)

    s.update(:test,'TEST',:up)
    s.changed?.should eq(true)

    #
    File.stub(:open).and_return(true)
    s.save

    s.changed?.should eq(false)
  end
end