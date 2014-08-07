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
        @wire_commands = Wire::WireCommands.new
      end

      def apply_globals
        options[:nocolor] && Rainbow.enabled = false
        options[:debug] && $log.level = Logger::DEBUG
      end

    end

    class_option :nocolor, { :desc => 'Disable coloring in output',
                             :required => false, :banner => '' }
    class_option :debug, { :desc => 'Show debug output', :banner => '' }

    # init
    #
    desc 'init [TARGETDIR]', 'create an inital model in TARGETDIR'
    long_desc <<-LONGDESC
      Creates TARGETDIR if necessary, opens an interactive
      console dialog about the model to be created.

      Writes model files to TARGETDIR.
    LONGDESC
    def init(target_dir = '.')
      initialize_commands
      apply_globals
      @wire_commands.run_init(target_dir)
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
      initialize_commands
      apply_globals
      @wire_commands.run_validate(target_dir)
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
      initialize_commands
      apply_globals
      @wire_commands.run_verify(target_dir)
    end

    # spec
    #
    desc 'spec [TARGETDIR]',
         'read model in TARGETDIR and create a serverspec' \
         'specification example in TARGETDIR'
    long_desc <<-LONGDESC
      Given a model in TARGETDIR, the verify commands reads
      the model. For each element it creates a serverspec-conformant
      describe()-block in a spec file.
      Writes spec helpers if they do not exist.
    LONGDESC
    option :run, { :desc => 'Automatically run serverspec', :banner => '', :type => :boolean }
    def spec(target_dir = '.')
      initialize_commands
      apply_globals
      @wire_commands.run_spec(target_dir, options[:run])
    end

    # up
    #
    desc 'up [TARGETDIR]',
         'read model in TARGETDIR and bring system up' \
         'according to model elements in TARGETDIR'
    long_desc <<-LONGDESC
      Given a model in TARGETDIR, the up commands reads
      the model. Each model element is brought to live.
    LONGDESC
    def up(target_dir = '.')
      initialize_commands
      apply_globals
      @wire_commands.run_up(target_dir)
    end

    # down
    #
    desc 'down [TARGETDIR]',
         'read model in TARGETDIR and bring system down' \
         'according to model elements in TARGETDIR'
    long_desc <<-LONGDESC
      Given a model in TARGETDIR, the up commands reads
      the model. Each model element is stopped and removed.
    LONGDESC
    def down(target_dir = '.')
      initialize_commands
      apply_globals
      @wire_commands.run_down(target_dir)
    end
  end
end
