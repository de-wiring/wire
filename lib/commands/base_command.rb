# encoding: utf-8

# Wire module
module Wire
  # (empty) Base command
  class BaseCommand
    attr_accessor :params, :project

    def outputs(type, msg, style = :plain)
      line = "#{type}=> #{msg}"
      if style == :err
        puts line.color(:red)
        return
      end

      if style == :ok
        puts line.color(:green)
        return
      end

      puts line
    end

    # runs the command, according to parameters
    # loads project into @project, calls run_on_project
    # (to be defined in subclasses)
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
