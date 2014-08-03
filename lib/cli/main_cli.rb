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
          :validate_command => ValidateCommand.new
        }
      end
    end

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
      res = @commands[:validate_command].run({ :target_dir => target_dir })
      if res.size == 0
        puts 'OK, model is consistent.'
      else
        puts 'ERROR, detected inconsistencies/errors:'
        res.each do |val_error|
          puts val_error.to_s
        end
      end
    end
  end
end
