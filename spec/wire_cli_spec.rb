require 'spec_helper'

describe WireCLI do
	
	let(:cli) { WireCLI.new }

	subject { cli }

	describe 'wirecli' do

		it 'should print the list of available commands' do
			r = `ruby ./lib/wire.rb`
			fail unless r =~ /Commands:/
		end

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

  end

end


