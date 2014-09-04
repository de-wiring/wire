# encoding: utf-8

# The MIT License (MIT)
# Copyright (c) 2014 Andreas Schmidt, andreas@de-wiring.net
#

# Wire module
module Wire
  # WireCLI
  # thor command line class
  #
  class WireCommands
    # internal array of +commands+ (as objects)
    attr_reader :commands

    # initialize wirecommands object
    def initialize
      initialize_commands
    end

    # pre-build array of available commands
    # see @commands
    def initialize_commands
      @commands = {
        :init_command => InitCommand.new,
        :validate_command => ValidateCommand.new,
        :verify_command => VerifyCommand.new,
        :spec_command => SpecCommand.new,
        :up_command => UpCommand.new,
        :down_command => DownCommand.new
      } unless @commands
    end

    # :reek:DuplicateCode
    # run the init command on +target_dir+ model
    def run_init(target_dir)
      commands[:init_command].run({ :target_dir => target_dir })
    end

    # :reek:DuplicateCode
    # run the validate command on +target_dir+ model
    def run_validate(target_dir)
      commands[:validate_command].run({ :target_dir => target_dir })
    end

    # run the verify command on +target_dir+ model
    def run_verify(target_dir)
      cmd_ver_obj = commands[:verify_command]
      cmd_ver_obj.run({ :target_dir => target_dir })
      if cmd_ver_obj.findings.size == 0
        puts 'OK, system is conforming to model'.color(:green)
      else
        puts 'ERROR, detected inconsistencies/errors.'.color(:red)
        # cmd_ver_obj.findings.each do |val_error|
        #   puts val_error.to_s
        # end
      end
    end

    # run the up command on +target_dir+ model
    def run_up(target_dir)
      # :reek:DuplicateCode
      if commands[:up_command].run({ :target_dir => target_dir })
        puts 'OK'.color(:green)
      else
        puts 'ERROR, detected errors'.color(:red)
      end
    end

    # run the down command on +target_dir+ model
    def run_down(target_dir)
      # :reek:DuplicateCode
      if commands[:down_command].run({ :target_dir => target_dir })
        puts 'OK'.color(:green)
      else
        puts 'ERROR, detected errors'.color(:red)
      end
    end

    # run the spec command on +target_dir+ model
    def run_spec(target_dir, b_run)
      commands[:spec_command].run({
                                    :target_dir => target_dir,
                                    :auto_run => b_run
                                  })
    end
  end
end
