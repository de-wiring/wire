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

      # filename of state file
      attr_accessor :statefile

      # initialize the object with
      # given appgroup +name+ and +container+ ids
      # params:
      # ++name++: Application group name
      # ++networks++: [Array] of network objects to attach containers to
      # ++containers++: [Array] of container ids (i.e. from fig ps -q)
      # ++statefile++: Optional name of (network) statefile
      def initialize(name, networks, containers, statefile = nil)
        super(name)
        self.containers = containers
        self.networks = networks
        self.statefile = statefile

        begin
          # try to locate the gem base path and find shell script
          gem 'dewiring'
          gem_base_dir = Gem.datadir('dewiring').split('/')[0..-3].join('/')
          @executables = {
            :network => File.join(gem_base_dir, 'lib/wire-network-container.sh')
          }
        rescue LoadError
          # use fallback
          @executables = {
            :network => '/usr/local/bin/wire-network-container.sh'
          }
        end
        $log.debug "Using network injection script #{@executables[:network]}"
      end

      # calls helper executable with correct +action+
      # and given +command_arr+ array
      def with_helper(action, params, options = '')
        # puts "#{@executables[:network]} #{action} --debug -- #{params.join(' ')}"
        dbg_param = ($log.level == Logger::DEBUG ? '--debug' : '')
        LocalExecution.with(@executables[:network],
                            [action, dbg_param, options, '--', params].flatten,
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
      # if a network defines a short name, it will be used for
      # the container interface.
      # will check if a network does not have dhcp enable and add a
      # NODHCP flag.
      def construct_helper_params
        res = []
        networks.each do |network_name, network_data|
          name = (network_data[:shortname]) ? network_data[:shortname] : network_name

          line = "#{name}:#{network_name}"
          (network_data[:dhcp]) || line << ':NODHCP'
          res << line
        end
        res.join(' ')
      end

      # same as exist?
      def up?
        with_helper('verify', [construct_helper_params,
                               containers.join(' ')], '--quiet') do |exec_obj|
          exec_obj.run

          return (exec_obj.exitstatus == 0 && count_errors(exec_obj) == 0)
        end
      end

      # Params:
      # ++cmd++: One of :attach, :detach
      def updown_command(cmd)
        $log.debug "About to #{cmd.to_s.capitalize} containers to networks ..."
        statefile_param = (@statefile) ? "-s #{@statefile}" : ''
        with_helper(cmd.to_s, [construct_helper_params,
                               containers.join(' ')], statefile_param) do |exec_obj|
          exec_obj.run
          return (exec_obj.exitstatus == 0 && count_errors(exec_obj) == 0)
        end
      end

      # attaches containers to networks
      def up
        updown_command :attach
      end

      # checks if the bridge is down
      def down?
        !(up?)
      end

      # detaches network interfaces form containers and bridges
      def down
        updown_command :detach
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
