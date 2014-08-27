# encoding: utf-8

# The MIT License (MIT)
# Copyright (c) 2014 Andreas Schmidt, andreas@de-wiring.net
#

include Wire::Execution

# Wire module
module Wire
  # Resource module
  module Resource
    # Fig Adapter resource, runs fig script
    # to control containers
    class FigAdapter < ResourceBase
      # +executables+ [Hash] of binaries needed to control
      # the resource
      attr_accessor :figfile, :executables

      # initialize the object with
      # given +name+ and path to fig file
      # params:
      # - name	fig filename name, i.e. "backend.yaml"
      def initialize(name, figfile)
        super(name.tr('_-', ''))
        @figfile = figfile

        # TODO: make configurable
        @executables = {
          :fig => '/usr/local/bin/fig'
        }
      end

      # checks if containers exist
      def exist?
        up?
      end

      # calls fig with correct -p and -f options
      # and given +command_arr+ array
      def with_fig(command_arr)
        LocalExecution.with(@executables[:fig],
                            ['-p', @name, '-f', @figfile, command_arr].flatten) do |exec_obj|
          yield exec_obj
        end
      end

      # checks if containers are up (using fig ps)
      def up?
        with_fig(%w(ps)) do |exec_obj|
          exec_obj.run

          # parse stdout..
          re = Regexp.new "^#{@name}.*Up.*"
          num_up = 0
          exec_obj.stdout.split("\n").each do |line|
            next unless line.match(re)

            $log.debug "Matching fig ps output: #{line}"

            num_up += 1
          end
          $log.debug 'No containers found in fig ps output' if num_up == 0

          return (exec_obj.exitstatus == 0 && num_up > 0)
        end
      end

      # returns the container ids of currently running containers
      def up_ids
        with_fig(%w(ps -q)) do |exec_obj|
          exec_obj.run

          # parse stdout..
          re = Regexp.new '^[0-9a-zA-Z]+'
          res = []

          exec_obj.stdout.split("\n").each do |line|
            next unless line.match(re)
            res << line.chomp.strip
          end

          return res
        end
        nil
      end

      # brings containers up
      def up
        $log.debug 'Bringing up fig containers ...'
        with_fig(%w(up -d --no-recreate)) do |exec_obj|
          exec_obj.run

          return (exec_obj.exitstatus == 0)
        end
      end

      # checks if the bridge is down
      def down?
        !(up?)
      end

      # takes containers down
      def down
        $log.debug 'Taking down fig containers ...'
        with_fig(['stop']) do |exec_obj|
          exec_obj.run

          return false if (exec_obj.exitstatus != 0)
        end
        $log.debug 'Removing fig containers ...'
        with_fig(%w(rm --force)) do |exec_obj|
          exec_obj.run

          return false if (exec_obj.exitstatus != 0)
        end
        true
      end

      # Returns a string representation
      def to_s
        "FigAdapter:[#{name},file=#{figfile}]"
      end
    end
  end
end
