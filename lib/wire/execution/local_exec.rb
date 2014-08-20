# encoding: utf-8

# The MIT License (MIT)
# Copyright (c) 2014 Andreas Schmidt, andreas@de-wiring.net
#

require 'singleton'

# Wire module
module Wire
  # Execution module for executing commands
  module Execution
    # return singleton object
    def self.global_execution_options
      ExecutionOptions.singleton
    end

    # Global execution options, such as noop mode etc.
    class ExecutionOptions
      include Singleton

      # set default execution options
      def initialize
        @options = { :b_noop => false }
      end

      # returns
      # - [Boolean] true if no_op mode
      def noop?
        @options[:b_noop]
      end
    end

    # Able to execute commands locally
    # supports sudo and shell wrapping
    class LocalExecution
      # +exitstatus+  the exit status of a command that we ran
      # +stdout+ stdout from command as [String]
      # +stderr+ stderr from command as [String]
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

      # block-style. Creates a LocalExecution object with
      # given parameters, yields it into a given block.
      # Params:
      # +command+ Command string, usually the binary
      # +args+    argument array
      # +options+ option map (b_shell, b_sudo flags)
      # Yields
      # - LocalExecution object
      def self.with(command, args = nil, options =
          { :b_shell => true, :b_sudo => true })
        obj = LocalExecution.new command, args, options
        yield obj
      end

      # constructs the single command line string from
      # given parameters.
      # Returns
      # - Command line as [String]
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

      # converts given +array_or_nil+ object to identity
      # if array or an empty array if nil
      def array_or_nil_as_str(array_or_nil)
        (array_or_nil || []).join(' ')
      end
    end
  end
end
