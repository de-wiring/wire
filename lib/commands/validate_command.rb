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

			pp project
			run_on_project project
		end


		def run_on_project(project)

			errors = []

			# run validations against it
			[ NetworksValidation ].each do |val_clazz|
				val_obj = val_clazz.new(project)
				val_obj.run_validations
				( errors << val_obj.errors ).flatten!
			end

			errors
		end


	end
		
end

