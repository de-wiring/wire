# encoding: utf-8

# The MIT License (MIT)
# Copyright (c) 2014 Andreas Schmidt, andreas@de-wiring.net
#

# Wire module
module Wire
  # (Empty) Base command
  class BaseCommand
    # +params+ object and +project+ to operate upon
    attr_accessor :params, :project

    # returns the state object
    def state
      State.instance
    end

    # debugs a single line state
    def dump_state
      $log.debug "State: [#{state.to_pretty_s}]"
    end

    # +outputs+ writes a message to stdout, in given style
    #
    # params:
    # +type+  1st column as type, i.e. "model" or "network" or "OK"
    # +msg+   message to print
    # +style+ coloring etc, supported:
    #         :plain (default), :err (red), :ok (green)
    # return
    # - nil
    #
    # :reek:ControlParameter
    def outputs(type, msg, style = :plain)
      line = "#{type}> #{msg}"
      line = line.color(:red) if (style == :err) || (style == :error)
      line = line.color(:green) if style == :ok
      line = line.color(:cyan) if style == :ok2

      $stdout.puts line
    end

    # Issues a warning if we do not run as root.
    def check_user
      (ENV['USER'] != 'root') &&
          $log.warn("Not running as root. Make sure user #{ENV['USER']} has sudo configured.")
    end

    # retrieve all objects of given +type_name+ in
    # zone (by +zone_name+)
    # returns:
    # [Hash] of model subpart with elements of given type
    def objects_in_zone(type_name, zone_name)
      return {} unless @project.element?(type_name)
      objects = @project.get_element type_name || {}
      objects.select { |_, data| data[:zone] == zone_name }
    end

    # runs the command, according to parameters
    # loads project into @project, calls run_on_project
    # (to be defined in subclasses)
    # params
    # +params+  command parameter map, example key i.e. "target_dir"
    def run(params = {})
      check_user

      @params = params
      target_dir = @params[:target_dir]
      outputs 'model', "Loading model in #{target_dir}"

      # load it first
      begin
        loader = ProjectYamlLoader.new
        @project = loader.load_project(target_dir)

        # try to load state file.
        state.project = @project
        handle_state_load

        run_on_project

        $log.debug? && pp(@project)

        handle_state_save

      rescue => load_execption
        $stderr.puts "Unable to process project model in #{target_dir}"
        $log.debug? && puts(load_execption.inspect)
        $log.debug? && puts(load_execption.backtrace)

        return false
      end
      true
    end

    # if the hostip is not in cidr, take netmask
    # from network entry, add to hostip
    # params:
    # +host_ip+ i.e. 192.168.10.1
    # +network_data+ network data object, to take netmask from :network element
    def ensure_hostip_netmask(host_ip, network_data)
      return host_ip  if host_ip =~ /[0-9\.]+\/[0-9]+/

      match_data = network_data[:network].match(/[0-9\.]+(\/[0-9]+)/)
      if match_data && match_data.size >= 2
        netmask = match_data[1]
        $log.debug "Adding netmask #{netmask} to host-ip #{host_ip}"
        return "#{host_ip}#{netmask}"
      else
        $log.error "host-ip #{host_ip} is missing netmask, and none given in network."
        return host_ip
      end
    end

    private

    # Save state to state file
    def handle_state_save
      # dump state
      $log.debug? && dump_state
      state.save
    rescue => save_exception
      $stderr.puts "Error saving state, #{save_exception}"
      $log.debug? && puts(save_exception.inspect)
      $log.debug? && puts(save_exception.backtrace)
    end

    def handle_state_load
      state.load
      # dump state
      $log.debug? && dump_state
    rescue => load_exception
      $stderr.puts "Error loading state, #{load_exception}"
      $log.debug? && puts(load_exception.inspect)
      $log.debug? && puts(load_exception.backtrace)
    end
  end
end
