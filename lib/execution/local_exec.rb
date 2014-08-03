# encoding: utf-8

module Wire
  module Execution

    # Able to execute commands locally
    class LocalExecution

      # params:
      # - command: binary to execute
      # - args: optional cmd line arguments (exec array)
      # - b_shell: if true, run as /bin/sh -c <command> [args]
      # - b_sudo: insert sudo if true
      def initialize(command, args, b_shell = true, b_sudo = true)
        @command = command
        @args = (args || []).join(' ')
        @b_shell = b_shell
        @b_sudo = b_sudo
      end

      def get_command
        cmd_arr = []
        sudo_str = (@b_sudo?'sudo':'')
        if @b_shell
          cmd_arr << '/bin/sh'
          cmd_arr << '-c'
          cmd_arr << "'#{sudo_str}#{command} #{args}'"
        else
          cmd_arr << "#{sudo_str}#{command} #{args}"
        end

        return cmd_arr.join(" ")
      end

      def run
        cmd = get_command

        @stdout =`#{cmd}`
        @stderr = nil
        @exitstatus = $?.exitstatus

      end

    end

  end
end