# encoding: utf-8

# Wire module
module Wire
  # Resource module
  module Resource
    # ResourceBase is the base class for all
    # resource elements
    class ResourceBase
      attr_accessor	:name

      def initialize(name)
        @name = name
      end

      def to_s
        "Resource:[#{name}]"
      end
    end
  end
end
