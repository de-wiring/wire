require 'spec_helper'

include Wire
include Wire::Resource

describe SpecCommand do
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

  let(:sc) { SpecCommand.new }
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

  it 'should fail on invalid target dir' do
    out_,err_ = streams_before
    res = sc.run({ :target_dir => 'nonexisting_project_for_spec'} )
    res.should eq(false)
    streams_after out_,err_
  end

  #it 'should generate a serverspec skeleton for a valid project' do
  #  sc.project = correct_project
  #  dir = Dir.mktmpdir
  #  begin
  #    out_,err_ = streams_before
  #    sc.target_dir = dir
  #    sc.run_on_project
  #    streams_after out_,err_
  #
  #    new_dir = File.join(dir,'serverspec')
  #    (File.exist?(new_dir)).should eq(true)
  #    (File.directory?(new_dir)).should eq(true)
  #  ensure
  #    # remove the directory.
  #    FileUtils.remove_entry_secure dir
  #  end
  #
  #end
  
  it 'should generate serverspec code' do
    sc.project = correct_project
    sc.run_on_project
    #sc.spec_code = []
    
    sc.spec_code.should_not eq(nil)
    sc.spec_code.size.should_not eq(0)
  end
end