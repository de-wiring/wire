# encoding: utf-8

# Wire module
module Wire
  # Validate Command reads yaml, parses model elements
  # and runs a number of consistency checks
  # params:
  # - :target_dir
  class ValidateCommand < BaseCommand
    def run(params = {})
      target_dir = params[:target_dir]
      puts "Validating model in #{target_dir}"

      # load it first
      begin
        loader = ProjectYamlLoader.new
        project = loader.load_project(target_dir)

        $log.debug? && pp(project)

        run_on_project project
      rescue => load_execption
        $stderr.puts "Unable to load project model from #{target_dir}"
        $log.debug? && puts(load_execption.backtrace)

        ['No project model file(s) found.']
      end
    end

    def run_validation(project, validation_class)
      $log.debug "Running validation class #{validation_class}"
      val_object = validation_class.new(project)
      val_object.run_validations
      val_object.errors
    end

    def run_on_project(project)
      errors = []

      # run validations against it
      [NetworksValidation].each do |val_clazz|
        (errors << run_validation(project, val_clazz)).flatten!
      end

      errors
    end
  end
end
