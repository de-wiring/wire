# encoding: utf-8

# The MIT License (MIT)
# Copyright (c) 2014 Andreas Schmidt, andreas@de-wiring.net
#

# Wire module
module Wire
  # (empty) Base command
  class BaseCommand
    # +params+ object and +project+ to operate upon
    attr_accessor :params, :project

    # +outputs+ writes a message to stdout, in given style
    #
    # params:
    # +type+  1st column as type, i.e. "model" or "network" or "OK"
    # +msg+   message to print
    # +style+ coloring etc, supported:
    #         :plain (default), :err (red), :ok (green)
    # return
    # - nil
    def outputs(type, msg, style = :plain)
      line = "#{type}> #{msg}"
      if style == :err
        $stdout.puts line.color(:red)
        return
      end

      if style == :ok
        $stdout.puts line.color(:green)
        return
      end

      $stdout.puts line
    end

    # runs the command, according to parameters
    # loads project into @project, calls run_on_project
    # (to be defined in subclasses)
    # params
    # +params+  command parameter map, example key i.e. "target_dir"
    def run(params = {})
      @params = params
      target_dir = @params[:target_dir]
      outputs 'model', "Loading model in #{target_dir}"
      # load it first
      begin
        loader = ProjectYamlLoader.new
        @project = loader.load_project(target_dir)

        run_on_project

        $log.debug? && pp(@project)
      rescue => load_execption
        $stderr.puts "Unable to load project model from #{target_dir}"
        $log.debug? && puts(load_execption.inspect)
        $log.debug? && puts(load_execption.backtrace)

        return false
      end
      true
    end
  end
end
