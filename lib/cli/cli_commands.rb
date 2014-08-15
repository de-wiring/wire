# encoding: utf-8

# Wire module
module Wire
  # WireCLI
  # thor command line class
  #
  class WireCommands
    def initialize
      initialize_commands
    end

    # pre-build array of available commands
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
    def run_init(target_dir)
      @commands[:init_command].run({ :target_dir => target_dir })
    end

    # :reek:DuplicateCode
    def run_validate(target_dir)
      cmd_val_obj = @commands[:validate_command]
      cmd_val_obj.run({ :target_dir => target_dir })
      if cmd_val_obj.errors.size == 0
        puts 'OK, model is consistent.'.color(:green)
      else
        puts 'ERROR, detected inconsistencies/errors:'.color(:red)
        cmd_val_obj.errors.each do |val_error|
          puts val_error.to_s
        end
      end
    end

    def run_verify(target_dir)
      cmd_ver_obj = @commands[:verify_command]
      cmd_ver_obj.run({ :target_dir => target_dir })
      if cmd_ver_obj.findings.size == 0
        puts 'OK, system is conforming to model'.color(:green)
      else
        puts 'ERROR, detected inconsistencies/errors:'.color(:red)
        cmd_ver_obj.findings.each do |val_error|
          puts val_error.to_s
        end
      end
    end

    def run_up(target_dir)
      # :reek:DuplicateCode
      if @commands[:up_command].run({ :target_dir => target_dir })
        puts 'OK'.color(:green)
      else
        puts 'ERROR, detected errors'.color(:red)
      end
    end

    def run_down(target_dir)
      # :reek:DuplicateCode
      if @commands[:down_command].run({ :target_dir => target_dir })
        puts 'OK'.color(:green)
      else
        puts 'ERROR, detected errors'.color(:red)
      end
    end

    def run_spec(target_dir, b_run)
      @commands[:spec_command].run({
                                     :target_dir => target_dir,
                                     :auto_run => b_run
                                   })
    end
  end
end
