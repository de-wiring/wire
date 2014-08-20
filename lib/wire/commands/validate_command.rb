# encoding: utf-8

# The MIT License (MIT)
# Copyright (c) 2014 Andreas Schmidt, andreas@de-wiring.net
#

# Wire module
module Wire
  # Validate Command reads yaml, parses model elements
  # and runs a number of consistency checks
  class ValidateCommand < BaseCommand
    # array of +errors+
    attr_accessor :errors

    # array of validations
    attr_accessor :validations

    # initializes an empty error list
    def initialize
      @errors = []
      @validations = [NetworksValidation]
    end

    # runs validation on given project
    # returns
    # => list of +errors+
    def run_on_project
      @errors = []

      # run validations against it
      # TODO: Move validation classes to class level definition
      @validations.each do |val_clazz|
        (@errors << run_validation(@project, val_clazz)).flatten!
      end

      if @errors.size == 0
        outputs 'VALIDATE', 'OK, model is consistent.', :ok
      else
        outputs 'VALIDATE', 'ERROR, detected inconsistencies:', :error
        @errors.each do |val_error|
          outputs 'VALIDATE', val_error.to_s, :error
        end
      end

      @errors
    end

    # run a validation of given +validation_class+ against
    # the model
    #
    # params:
    # +project+           project model object, to validate
    # +validation_class+  class object of validation, i.e. NetworksValidation
    #
    # returns:
    # list of errors from validation object
    def run_validation(project, validation_class)
      $log.debug "Running validation class #{validation_class}"
      val_object = validation_class.new(project)
      val_object.run_validations
      val_object.errors
    end
  end
end
