# encoding: utf-8

# Wire module
module Wire
  # raised in case of model elements
  # not running
  class VerificationError
    attr_accessor	:message, :element_type, :element_name, :element

    def initialize(message, element_type, element_name, element)
      @message = message
      @element_type = element_type
      @element_name = element_name
      @element = element
    end

    def to_s
      "VerificationError on #{@element_type} #{@element_name} : #{@message}"
    end
  end
end
