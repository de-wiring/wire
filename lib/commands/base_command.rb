# encoding: utf-8

# Wire module
module Wire
  # (empty) Base command
  class BaseCommand
    attr_accessor :params

    # runs the command, according to parameters
    # loads project into @project, calls run_on_project
    # (to be defined in subclasses)
    def run(params = {})
      @params = params
      target_dir = @params[:target_dir]
      puts "Bringing up model in #{target_dir}"
      # load it first
      begin
        loader = ProjectYamlLoader.new
        @project = loader.load_project(target_dir)

        run_on_project

        $log.debug? && pp(@project)
      rescue => load_execption
        $stderr.puts "Unable to load project model from #{target_dir}"
        $log.debug? && puts(load_execption.backtrace)

        return false
      end
      true
    end
  end
end
