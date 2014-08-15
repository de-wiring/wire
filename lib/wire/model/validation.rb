# encoding: utf-8

# Wire module
module Wire
  # raised in case of invalid model
  class ValidationError
    attr_accessor	:message, :element_type, :element_name

    def initialize(message, element_type, element_name)
      @message = message
      @element_type = element_type
      @element_name = element_name
    end

    def to_s
      "ValidationError on #{@element_type} #{@element_name}: #{@message}"
    end
  end

  # Validation Base class
  class ValidationBase
    attr_accessor	:errors

    def initialize(project)
      @project = project
      @errors = []
    end

    def mark(message, element_type, element_name)
      @errors << ValidationError.new(message, element_type, element_name)
    end
  end
end
