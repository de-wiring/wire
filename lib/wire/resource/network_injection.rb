# encoding: utf-8

# The MIT License (MIT)
# Copyright (c) 2014 Andreas Schmidt, andreas@de-wiring.net
#

include Wire::Execution

# Wire module
module Wire
  # Resource module
  module Resource
    # Network Injection Resource controls the allocation
    # of host and container network resources for
    # all containers of an application group
    class NetworkInjection < ResourceBase
      # +executables+ [Hash] of binaries needed to control
      # the resource
      attr_accessor :executables

      # ids of containers of appgroup
      attr_accessor :containers

      # names of networks to attach appgroup containers to
      attr_accessor :networks

      # initialize the object with
      # given appgroup +name+ and +container+ ids
      # params:
      # ++name++: Application group name
      # ++networks++: [Array] of network names to attach containers to
      # ++containers+: [Array] of container ids (i.e. from fig ps -q)
      def initialize(name, networks, containers)
        super(name)
        self.containers = containers
        self.networks = networks

        # TODO: make configurable
        @executables = {
          :network => '/usr/local/bin/wire-network-container.sh'
        }
      end

      # calls helper executable with correct +action+
      # and given +command_arr+ array
      def with_helper(action, params)
        # puts "#{@executables[:network]} #{action} --debug -- #{params.join(' ')}"
        LocalExecution.with(@executables[:network],
                            [action, '--debug', '--', params].flatten,
                            { :b_sudo => false, :b_shell => false }) do |exec_obj|
          yield exec_obj
        end
      end

      # calls the verify action to see if container
      # has been networked correctly
      def exist?
        up?
      end

      # for the network helper script, construct
      # an array of container devices names and bridge names,
      # i.e. eht1:br0 meaning container will be attached
      # to bridge br0 with eth1.
      # first iteration: choose device=network_name=bridge_name,
      # all the same.
      def construct_helper_params
        res = []
        networks.each do |network|
          res << "#{network}:#{network}"
        end
        res.join(' ')
      end

      # same as exist?
      def up?
        with_helper('verify', [construct_helper_params,
                               containers.join(' ')]) do |exec_obj|
          exec_obj.run

          return (exec_obj.exitstatus == 0 && count_errors(exec_obj) == 0)
        end
      end

      # attaches containers to networks
      def up
        $log.debug 'Attaching containers to networks ...'
        with_helper('attach', [construct_helper_params,
                               containers.join(' ')]) do |exec_obj|
          exec_obj.run

          return (exec_obj.exitstatus == 0 && count_errors(exec_obj) == 0)
        end
      end

      # checks if the bridge is down
      def down?
        !(up?)
      end

      # detaches network interfaces form containers and bridges
      def down
        $log.debug 'Taking down container network attachments ...'
        with_helper('detach', [construct_helper_params,
                               containers.join(' ')]) do |exec_obj|
          exec_obj.run

          return (exec_obj.exitstatus == 0 && count_errors(exec_obj) == 0)
        end
      end

      # Returns a string representation
      def to_s
        "NetworkInjection:[#{name},containers=#{containers.join('/')}," \
        "network_args=#{construct_helper_params}]"
      end

      private

      # counts errors in a text output from given
      # +exec_obj+
      def count_errors(exec_obj)
        num_errors = 0
        re = Regexp.new '^ERROR.*'
        exec_obj.stdout.split("\n").each do |line|
          $log.debug line

          next unless line.match(re)

          $log.debug "Matching error output: #{line}"

          num_errors += 1
        end
        num_errors
      end
    end
  end
end
