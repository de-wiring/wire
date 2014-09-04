require 'spec_helper'

describe ValidationError do
  before(:all) do
    Object.any_instance.stub(:"`").and_return('')
  end


  it 'should display ValidationErrors correctly' do
    error = ValidationError.new 'FooMessage', 'FooType', 'FooObject'
    error.to_s.should eq('ValidationError on FooType FooObject: FooMessage')
	end

  it 'should store ValidationErrors in ValidationBase' do
    project = "Project"
    vb = ValidationBase.new(project)
    vb.mark 'FooMessage', 'FooType', 'FooObject'

    vb.errors.size.should eq(1)
    vb.errors[0].to_s.should eq('ValidationError on FooType FooObject: FooMessage')
  end
end

describe ValidateCommand do
  before(:all) do
    Object.any_instance.stub(:"`").and_return('')
  end

  let(:correct_project) {
    p = Project.new(".")
    p.merge_element(:zones,
                    { 'z1' => { } }
    )
    p.merge_element(:networks,
                    { 'n1' => { :zone => 'z1', :network => '10.0.0.0/8', :hostip => '10.10.1.1',
                      :dhcp => { :start => '10.10.1.10', :end => '10.10.1.250'}} }
    )
    p
  }
  let(:incorrect_project_dupe_networks) {
    p = Project.new(".")
    p.merge_element(:zones,
                    { 'z1' => { } }
    )
    p.merge_element(:networks,
                    {
                      'n1' => { :zone => 'z1', :network => '10.0.0.0/8'},
                      'n2' => { :zone => 'z1', :network => '10.0.0.0/8'},
                    }
    )
    p
  }
  let(:incorrect_project_no_networks) {
    p = Project.new(".")
    p.merge_element(:zones,
                    { 'z1' => { } }
    )
    p.merge_element(:networks,
                    {
                      'n1' => { :zone => 'z1', :network => '10.0.0.0/8'},
                      'n2' => { :zone => 'z1'},
                    }
    )
    p
  }
  let(:incorrect_project_nonmatching_hostip) {
    p = Project.new(".")
    p.merge_element(:zones,
                    { 'z1' => { } }
    )
    p.merge_element(:networks,
                    {
                      'n1' => { :zone => 'z1', :network => '10.0.0.0/8', :hostip => '192.168.1.10'}
                    }
    )
    p
  }
  let(:correct_appgroup) {
    p = Project.new(".")
    p.merge_element(:zones,
                    { 'z1' => { } }
    )
    p.merge_element(:networks,
                    { 'n1' => { :zone => 'z1', :network => '10.0.0.0/8'} }
    )
    p.merge_element(:appgroups,
                    { 'g1' => { :zone => 'z1', :controller => { :type => 'fig'}} }
    )
    p
  }
  let(:incorrect_appgroup_missingzone) {
    p = Project.new(".")
    p.merge_element(:zones,
                    { 'z1' => { } }
    )
    p.merge_element(:networks,
                    { 'n1' => { :zone => 'z1', :network => '10.0.0.0/8'} }
    )
    p.merge_element(:appgroups,
                    { 'g1' => { } }
    )
    p
  }
  let(:incorrect_appgroup_unknown_controller) {
    p = Project.new(".")
    p.merge_element(:zones,
                    { 'z1' => { } }
    )
    p.merge_element(:networks,
                    { 'n1' => { :zone => 'z1', :network => '10.0.0.0/8'} }
    )
    p.merge_element(:appgroups,
                    { 'g1' => { :zone => 'z1', :controller => { :type => 'UNKNOWN'}} }
    )
    p
  }
  let(:incorrect_project_dhcp_ranges) {
    p = Project.new(".")
    p.merge_element(:zones,
                    { 'z1' => { } }
    )
    p.merge_element(:networks,
                    { 'n1' => { :zone => 'z1', :network => '10.0.0.0/8', :hostip => '10.10.1.1',
                                :dhcp => { :start => '192.168.1.1', :end => '172.17.19.20'}} }
    )
    p
  }
  let(:incorrect_project_dhcp_badranges) {
    p = Project.new(".")
    p.merge_element(:zones,
                    { 'z1' => { } }
    )
    p.merge_element(:networks,
                    { 'n1' => { :zone => 'z1', :network => '10.0.0.0/8', :hostip => '10.10.1.1',
                                :dhcp => { :start => 'a.b.c.d', :end => 'e.f.g.h'}} }
    )
    p
  }
  let(:incorrect_project_dhcp_noranges) {
    p = Project.new(".")
    p.merge_element(:zones,
                    { 'z1' => { } }
    )
    p.merge_element(:networks,
                    { 'n1' => { :zone => 'z1', :network => '10.0.0.0/8', :hostip => '10.10.1.1',
                                :dhcp => { }} }
    )
    p
  }
  let(:incorrect_project_dhcp_no_hostip) {
    p = Project.new(".")
    p.merge_element(:zones,
                    { 'z1' => { } }
    )
    p.merge_element(:networks,
                    { 'n1' => { :zone => 'z1', :network => '10.0.0.0/8',
                                :dhcp => { :start => '192.168.1.1', :end => '172.17.19.20'}} }
    )
    p
  }
  let(:vc) { ValidateCommand.new }

  it 'should yield no errors on a correct sample project' do
    out_,err_ = streams_before
    vc.project =  correct_project
    errors = vc.run_on_project
    streams_after out_,err_

    pp(errors) if errors.size != 0
    errors.size.should eq(0)
  end

  it 'should yield no errors on a correct appgroup' do
    out_,err_ = streams_before
    vc.project =  correct_appgroup
    errors = vc.run_on_project
    streams_after out_,err_

    pp(errors) if errors.size != 0
    errors.size.should eq(0)
  end

  it 'should fail on incorrect sample projects' do
    out_,err_ = streams_before
    vc.project =  incorrect_project_dupe_networks
    errors = vc.run_on_project
    streams_after out_,err_
    errors.size.should eq(1)

    out_,err_ = streams_before
    vc.project =  incorrect_project_no_networks
    errors = vc.run_on_project
    streams_after out_,err_
    errors.size.should eq(1)

    out_,err_ = streams_before
    vc.project =  incorrect_appgroup_missingzone
    errors = vc.run_on_project
    streams_after out_,err_
    errors.size.should eq(2)

    out_,err_ = streams_before
    vc.project =  incorrect_appgroup_unknown_controller
    errors = vc.run_on_project
    streams_after out_,err_
    errors.size.should eq(1)

    out_,err_ = streams_before
    vc.project =  incorrect_project_dhcp_ranges
    errors = vc.run_on_project
    streams_after out_,err_
    errors.size.should eq(2)

    out_,err_ = streams_before
    vc.project =  incorrect_project_dhcp_no_hostip
    errors = vc.run_on_project
    streams_after out_,err_
    errors.size.should eq(1)

    out_,err_ = streams_before
    vc.project =  incorrect_project_dhcp_noranges
    errors = vc.run_on_project
    streams_after out_,err_
    errors.size.should eq(1)

    out_,err_ = streams_before
    vc.project =  incorrect_project_dhcp_badranges
    errors = vc.run_on_project
    streams_after out_,err_
    errors.size.should eq(1)

  end

  it 'should fail on nonmatching hostip' do
    out_,err_ = streams_before
    vc.project =  incorrect_project_nonmatching_hostip
    errors = vc.run_on_project
    streams_after out_,err_
    errors.size.should eq(1)
  end

  it 'should fail on invalid target dir' do
    out_,err_ = streams_before
    res = vc.run({ :target_dir => 'nonexisting_project_validation'} )
    res.should eq(false)
    streams_after out_,err_
  end
end


