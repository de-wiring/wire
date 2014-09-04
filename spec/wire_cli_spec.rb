require 'spec_helper'

describe 'WireCLI external call' do
  describe 'wirecli call' do
    it 'should print the list of available commands' do
      r = `ruby ./lib/wire.rb`
      fail unless r =~ /Commands:/
    end

    # ... add more
  end
end

describe WireCLI do
  before(:all) do
    Object.any_instance.stub(:"`").and_return('')
  end
  let(:cli) { WireCLI.new }

	subject { cli }

  describe 'wirecli' do
		it 'should have the init command' do
			fail unless cli.methods.include? :init
		end

		it 'should have the validate command' do
			fail unless cli.methods.include? :validate
		end

    it 'should have the verify command' do
      fail unless cli.methods.include? :verify
    end

    it 'should have the spec command' do
      fail unless cli.methods.include? :spec
    end

    it 'should have the up command' do
      fail unless cli.methods.include? :up
    end

    it 'should have the down command' do
      fail unless cli.methods.include? :down
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

		it 'should fail on init with empty zone input' do
			STDIN.should_receive(:gets).and_return("\n")
			out_,err_ = streams_before
			lambda {
				cli.init
			}.should raise_error SystemExit
			$stderr.string.should match(/^ERROR.*/)
			streams_after out_,err_
		end

		it 'should fail when target_dir is invalid' do
			STDIN.should_receive(:gets).and_return("nozone\n")
			STDIN.should_receive(:gets).and_return("\n")

			out_,err_ = streams_before
			lambda {
				cli.init('')
			}.should raise_error SystemExit

			$stderr.string.should match(/^ERROR.*/)
			streams_after out_,err_
		end

    it 'should fail on init with empty network input' do
      STDIN.should_receive(:gets).and_return("nozone\n")
      STDIN.should_receive(:gets).and_return("nonetwork\n")
      STDIN.should_receive(:gets).and_return("\n")
      STDIN.should_receive(:gets).and_return("\n")

      out_,err_ = streams_before
      lambda {
        cli.init('')
      }.should raise_error SystemExit

      $stderr.string.should match(/^ERROR.*/)
      streams_after out_,err_
    end

    it 'should create a directory structure when exporting a project' do
      STDIN.should_receive(:gets).and_return("nozone\n")
      STDIN.should_receive(:gets).and_return("nonetwork\n")
      STDIN.should_receive(:gets).and_return("1.2.3.4/32\n")
      STDIN.should_receive(:gets).and_return("\n")

      dir = Dir.mktmpdir
      begin
        out_,err_ = streams_before
        cli.init(dir)
        streams_after out_,err_

        new_dir = File.join(dir,'zones.yaml')
        (File.exist?(new_dir)).should eq(true)
      ensure
        # remove the directory.
        FileUtils.remove_entry_secure dir
      end

    end

    it 'should run a validation command on correct model' do
      begin
        out_,err_ = streams_before
        cli.validate('./spec/data')

        $stderr.string.should_not match(/ERROR.*/)
        $stdout.string.should match(/OK/)
      ensure
        streams_after out_,err_
      end
    end

    it 'should create a serverspec directory structure when run with spec command' do

      dir = Dir.mktmpdir
      begin
        `cp -rp ./spec/data/* #{dir}/`

        out_,err_ = streams_before
        cli.spec(dir)
        streams_after out_,err_

        new_dir = File.join(dir,'serverspec')
        (File.exist?(new_dir)).should eq(true)
      ensure
        streams_after out_,err_
        # remove the directory.
        FileUtils.remove_entry_secure dir
      end

    end
  end



  it 'should run a verify command on correct model and return positive output' do
    begin
      out_,err_ = streams_before
      mock_commands = WireCommands.new
      ver_cmd_double = double('VerifyCommand')
      mock_commands.stub(:commands).and_return({:verify_command => ver_cmd_double })

      ver_cmd_double.stub(:run).and_return(true)
      ver_cmd_double.stub(:findings).and_return([])
      mock_commands.run_verify('./spec/data')

      $stdout.string.should_not match(/ERROR.*/)
      $stdout.string.should match(/OK/)
    ensure
      streams_after out_,err_
    end
  end

  it 'should run a verify command on incorrect model and return negative output and findings' do
    begin
      out_,err_ = streams_before
      mock_commands = WireCommands.new
      ver_cmd_double = double('VerifyCommand')
      mock_commands.stub(:commands).and_return({:verify_command => ver_cmd_double })

      ver_cmd_double.stub(:run)
      ver_cmd_double.stub(:findings).and_return(['FooFinding'])
      mock_commands.run_verify('./spec/data')

      $stdout.string.should match(/ERROR.*/)
      $stdout.string.should_not match(/OK/)
    ensure
      streams_after out_,err_
    end
  end

  it 'should handle run_up correctly' do
    begin
      out_,err_ = streams_before
      mock_commands = WireCommands.new
      cmd_double = double('UpCommand')
      mock_commands.stub(:commands).and_return({:up_command => cmd_double })

      cmd_double.stub(:run).and_return true
      mock_commands.run_up('./spec/data')

      $stdout.string.should_not match(/ERROR.*/)
      $stdout.string.should match(/OK/)
    ensure
      streams_after out_,err_
    end

    begin
      out_,err_ = streams_before
      mock_commands = WireCommands.new
      cmd_double = double('UpCommand')
      mock_commands.stub(:commands).and_return({:up_command => cmd_double })

      cmd_double.stub(:run).and_return false
      mock_commands.run_up('./spec/data')

      $stdout.string.should match(/ERROR.*/)
      $stdout.string.should_not match(/OK/)
    ensure
      streams_after out_,err_
    end
  end

  it 'should handle run_down correctly' do
    begin
      out_,err_ = streams_before
      mock_commands = WireCommands.new
      cmd_double = double('DownCommand')
      mock_commands.stub(:commands).and_return({:down_command => cmd_double })

      cmd_double.stub(:run).and_return true
      mock_commands.run_down('./spec/data')

      $stdout.string.should_not match(/ERROR.*/)
      $stdout.string.should match(/OK/)
    ensure
      streams_after out_,err_
    end

    begin
      out_,err_ = streams_before
      mock_commands = WireCommands.new
      cmd_double = double('DownCommand')
      mock_commands.stub(:commands).and_return({:down_command => cmd_double })

      cmd_double.stub(:run).and_return false
      mock_commands.run_down('./spec/data')

      $stdout.string.should match(/ERROR.*/)
      $stdout.string.should_not match(/OK/)
    ensure
      streams_after out_,err_
    end
  end

end


