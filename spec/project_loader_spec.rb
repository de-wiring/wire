require 'spec_helper.rb'


describe ProjectYamlLoader do

  it 'load_project should fail on nonexisting directory' do
    pyl = ProjectYamlLoader.new
    lambda {
      pyl.load_project('./spec/data-nonexisting')
    }.should raise_error

  end

  it 'load_project should print stats on existing project' do
    pyl = ProjectYamlLoader.new

    out_, err_ = streams_before

    begin
      pyl.load_project('./spec/data')

      x = $stdout.string
      x.should match(/1 zone/)
      x.should match(/2 network/)

    ensure
      streams_after out_, err_
    end


  end

end
