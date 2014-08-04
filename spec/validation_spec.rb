require 'spec_helper'

describe ValidationError do

  it 'should display ValidationErrors correctly' do
    error = ValidationError.new 'FooMessage', 'FooType', 'FooObject'
    error.to_s.should eq('ValidationError on FooType FooObject : FooMessage')
	end

  it 'should store ValidationErrors in ValidationBase' do
    project = "Project"
    vb = ValidationBase.new(project)
    vb.mark 'FooMessage', 'FooType', 'FooObject'

    vb.errors.size.should eq(1)
    vb.errors[0].to_s.should eq('ValidationError on FooType FooObject : FooMessage')
  end
end


