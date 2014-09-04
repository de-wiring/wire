require 'spec_helper'

include Wire
include Wire::Resource

describe SpecCommand do
  before(:all) do
    Object.any_instance.stub(:"`").and_return('')
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

  let(:sc) {
    sc = SpecCommand.new
    sc.params = { :target_dir => '.' }
    sc
  }
  let(:correct_project) {
    p = Project.new('.')
    p.merge_element(:zones,
                    { 'z1' => { } }
    )
    p.merge_element(:networks,
                    { 'n1' => { :zone => 'z1', :network => '10.0.0.0/8', :hostip => '10.10.1.1',
                                :dhcp => { :start => '10.10.1.10', :end => '10.10.1.250'}}
                    }
    )
    p.merge_element(:appgroups,
                    { 'g1' => { :zone => 'z1', :controller => { :type => 'fig'}} }
    )
    p
  }

  it 'should fail on invalid target dir' do
    out_,err_ = streams_before
    res = sc.run({ :target_dir => 'nonexisting_project_for_spec'} )
    res.should eq(false)
    streams_after out_,err_
  end
  
  it 'should generate serverspec code' do
    sc.project = correct_project
    dir = Dir.mktmpdir
    begin
      sc.params = { :target_dir => dir }
      out_,err_ = streams_before

      sc.run_on_project
      streams_after out_,err_

      sc.spec_code.should_not eq(nil)
      sc.spec_code.size.should_not eq(0)

    ensure
      # remove the directory.
      FileUtils.remove_entry_secure dir
    end

  end

  it 'should call serverspec' do

    sc.should_receive(:"`").with(/cd nonexisting_project_for_spec \&\& sudo rake spec/).and_return(true)

    res = sc.run_serverspec('nonexisting_project_for_spec' )
    res.should eq(nil)

  end
end

describe SpecWriter do
  before(:all) do
    Object.any_instance.stub(:"`").and_return('')
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

  let(:test_contents) { [ 'spec-test-contents' ] }

  it 'should write a serverspec skeleton and sample code' do
    dir = Dir.mktmpdir
    begin

      out_,err_ = streams_before
      sp = SpecWriter.new(dir,test_contents)
      sp.write
      streams_after out_,err_

      new_dir = File.join(dir,'spec')
      (File.exist?(new_dir) && File.directory?(new_dir)).should eq(true)
      new_dir = File.join(dir,'Rakefile')
      (File.exist?(new_dir)).should eq(true)
      new_dir = File.join(dir,'spec','localhost')
      (File.exist?(new_dir) && File.directory?(new_dir)).should eq(true)
      new_dir = File.join(dir,'spec','spec_helper.rb')
      (File.exist?(new_dir)).should eq(true)
    ensure
      # remove the directory.
      FileUtils.remove_entry_secure dir
    end

  end
end