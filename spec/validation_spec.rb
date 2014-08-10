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

describe NetworksValidation do
  it 'should validate correctly a sample project' do
    p = Project.new(".")
    p.merge_element(:zones,
          { 'z1' => { } }
    )
    p.merge_element(:networks,
          { 'n1' => { :zone => 'z1'} }
    )

    nw = NetworksValidation.new(p)
    nw.run_validations

    nw.errors.size.should eq(0)

  end
end

describe ValidateCommand do
  let(:vc) { ValidateCommand.new }
  let(:correct_project) {
    p = Project.new(".")
    p.merge_element(:zones,
                    { 'z1' => { } }
    )
    p.merge_element(:networks,
                    { 'n1' => { :zone => 'z1'} }
    )
    p
  }

  it 'should yield no errors on a correct sample project' do
    errors = vc.run_on_project(correct_project)
    errors.size.should eq(0)
  end


  def streams_before
    out_ = $stdout
    err_ = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new
    return out_,err_
  end

  def streams_after(out_,err_)
    $stdout = out_
    $stderr = err_
  end

  it 'should fail on invalid target dir' do
    out_,err_ = streams_before
    res = vc.run({ :target_dir => 'nonexisting_project_validation'} )
    res.should eq(false)
    streams_after out_,err_
  end
end


