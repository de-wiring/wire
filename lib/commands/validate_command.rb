# encoding: utf-8

# Wire module
module Wire
  # Validate Command reads yaml, parses model elements
  # and runs a number of consistency checks
  # params:
  # - :target_dir
  class ValidateCommand < BaseCommand
    attr_accessor :errors

    def initialize
      @errors = []
    end

    def run_on_project(project)
      @errors = []

      # run validations against it
      [NetworksValidation].each do |val_clazz|
        (@errors << run_validation(project, val_clazz)).flatten!
      end

      @errors
    end

    def run_validation(project, validation_class)
      $log.debug "Running validation class #{validation_class}"
      val_object = validation_class.new(project)
      val_object.run_validations
      val_object.errors
    end
  end
end
