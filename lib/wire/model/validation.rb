# encoding: utf-8

# The MIT License (MIT)
# Copyright (c) 2014 Andreas Schmidt, andreas@de-wiring.net
#

# Wire module
module Wire
  # raised in case of invalid model
  class ValidationError
    # +message+   Validation Error message
    # +element_type+  Model element type of this error, i.e. 'Network'
    # +element_name+  Model element name
    attr_accessor	:message, :element_type, :element_name

    # Initializes the error object
    # Params:
    # +message+   Validation Error message
    # +element_type+  Model element type of this error, i.e. 'Network'
    # +element_name+  Model element name
    def initialize(message, element_type, element_name)
      @message = message
      @element_type = element_type
      @element_name = element_name
    end

    # returns a string representation
    def to_s
      "ValidationError on #{@element_type} #{@element_name}: #{@message}"
    end
  end

  # Validation Base class
  class ValidationBase
    # +errors+  Array of validation errors, see class ValidationError
    attr_accessor	:errors

    # initializes the Validation object on given +project+
    def initialize(project)
      @project = project
      @errors = []
    end

    # adds a validation error to the error list
    # +message+   Validation Error message
    # +element_type+  Model element type of this error, i.e. 'Network'
    # +element_name+  Model element name
    def mark(message, element_type, element_name)
      @errors << ValidationError.new(message, element_type, element_name)
    end
  end
end
