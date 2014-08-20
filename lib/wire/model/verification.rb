# encoding: utf-8

# The MIT License (MIT)
# Copyright (c) 2014 Andreas Schmidt, andreas@de-wiring.net
#

# Wire module
module Wire
  # raised in case of model elements
  # not running or in other verification
  # states
  class VerificationError
    # +message+ verification (error) message
    # +element_type+ element type as string (i.e. 'network')
    # +element_name+ name of element within model
    # +element+ reference to model element
    attr_accessor	:message, :element_type, :element_name, :element

    # initalizes the verification error
    # +message+ verification (error) message
    # +element_type+ element type as string (i.e. 'network')
    # +element_name+ name of element within model
    # +element+ reference to model element
    def initialize(message, element_type, element_name, element)
      @message = message
      @element_type = element_type
      @element_name = element_name
      @element = element
    end

    # string representation
    def to_s
      "VerificationError on #{@element_type} #{@element_name} : #{@message}"
    end
  end
end
