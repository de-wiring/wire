# encoding: utf-8
require 'singleton'

# Wire module
module Wire
  # Execution module for executing commands
  module Execution
    def self.global_execution_options
      ExecutionOptions.singleton
    end

    # Global execution options, such as noop mode etc.
    class ExecutionOptions
      include Singleton

      def initialize
        @options = { :b_noop => false }
      end

      def noop?
        @options[:b_noop]
      end
    end

    # Able to execute commands locally
    # supports sudo and shell wrapping
    class LocalExecution
      attr_accessor :exitstatus, :stdout, :stderr

      # params:
      # - command: binary to execute
      # - args: optional cmd line arguments (exec array)
      # - options:
      #   - b_shell: if true, run as /bin/sh -c '<command> [args]'
      #   - b_sudo: insert sudo if true
      def initialize(command, args = nil, options =
          { :b_shell => true, :b_sudo => true })
        @command = command
        @args = array_or_nil_as_str(args)
        @options = options
      end

      def self.with(command, args = nil, options =
          { :b_shell => true, :b_sudo => true })
        obj = LocalExecution.new command, args, options
        yield obj
      end

      # constructs the single command line string from
      # given parameters.
      def construct_command
        cmd_arr = []
        command_args = "#{@command} #{@args}".strip
        sudo_str = (@options[:b_sudo] ? 'sudo ' : '')
        if @options[:b_shell]
          cmd_arr << '/bin/sh'
          cmd_arr << '-c'

          cmd_arr << "'#{sudo_str}#{command_args}'"
        else
          cmd_arr << "#{sudo_str}#{command_args}"
        end

        cmd_arr.join(' ').strip
      end

      # runs the command
      # sets instance variables
      # stdout, stderr, exitstatus
      def run
        cmd = construct_command

        $log.debug "Executing #{cmd}"
        @stdout = `#{cmd}`
        @stderr = nil
        @exitstatus = $CHILD_STATUS.exitstatus
        # @exitstatus = $?.exitstatus
      end

      private

      def array_or_nil_as_str(array_or_nil)
        (array_or_nil || []).join(' ')
      end
    end
  end
end
