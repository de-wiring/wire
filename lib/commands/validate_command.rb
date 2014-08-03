# encoding: utf-8

module Wire

	# Validate Command reads yaml, parses model elements
	# and runs a number of consistency checks
	# params:
	# - :target_dir  
	class ValidateCommand < BaseCommand

		def run(params = {})
			puts "Validating model in #{params[:target_dir]}"

			# load it first
			loader = ProjectYamlLoader.new
			project = loader.load_project(params[:target_dir])

      if $log.debug?
			  pp project
      end

			run_on_project project
		end

    def run_validation(project,validation_class)
      $log.debug "Running validation class #{validation_class}"
      val_object = validation_class.new(project)
      val_object.run_validations
      val_object.errors
    end

		def run_on_project(project)

			errors = []

			# run validations against it
			[ NetworksValidation ].each do |val_clazz|
				( errors << run_validation(project,val_clazz) ).flatten!
			end

			errors
		end


	end
		
end

