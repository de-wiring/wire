# encoding: utf-8

# Wire module
module Wire
  # WireCLI
  # thor command line class
  #
  class WireCLI < Thor
    # treat as non-thor commands
    no_commands do
      # pre-build array of available commands
      def initialize_commands
        @commands = {
          :init_command => InitCommand.new,
          :validate_command => ValidateCommand.new,
          :verify_command => VerifyCommand.new
        }
      end

      def apply_globals
        if options[:nocolor]
          Rainbow.enabled = false
        end
        if options[:debug]
          $log.level = Logger::DEBUG
        end
      end
    end

    class_option :nocolor, :desc => 'Disable coloring in output', :required => false
    class_option :debug, :desc => 'Show debug output'

    # init
    #
    desc 'init [TARGETDIR]', 'create an inital model in TARGETDIR'
    long_desc <<-LONGDESC
      Creates TARGETDIR if necessary, opens an interactive
      console dialog about the model to be created.

      Writes model files to TARGETDIR.
    LONGDESC
    def init(target_dir = '.')
      initialize_commands unless @commands
      apply_globals
      @commands[:init_command].run({ :target_dir => target_dir })
    end

    # validate
    #
    desc 'validate [TARGETDIR]',
         'read model in TARGETDIR and validate its consistency'
    long_desc <<-LONGDESC
      Given a model in TARGETDIR, the validate commands reads
      the model and runs consistency checks against the model elements,
      i.e. if every network is attached to a zone.
    LONGDESC
    def validate(target_dir = '.')
      initialize_commands unless @commands
      apply_globals
      res = @commands[:validate_command].run({ :target_dir => target_dir })
      if res.size == 0
        puts 'OK, model is consistent.'.color(:green)
      else
        puts 'ERROR, detected inconsistencies/errors:'.color(:red)
        res.each do |val_error|
          puts val_error.to_s
        end
      end
    end

    # verify
    #
    desc 'verify [TARGETDIR]',
         'read model in TARGETDIR and verify against current system'
    long_desc <<-LONGDESC
      Given a model in TARGETDIR, the verify commands reads
      the model and runs checks to see if everthing in the model
      is present in the current system.
    LONGDESC
    def verify(target_dir = '.')
      initialize_commands unless @commands
      apply_globals
      res = @commands[:verify_command].run({ :target_dir => target_dir })
      if res.size == 0
        puts 'OK, system is conforming to model'.color(:green)
      else
        puts 'ERROR, detected inconsistencies/errors:'.color(:red)
        res.each do |val_error|
          puts val_error.to_s
        end
      end
    end
  end
end
