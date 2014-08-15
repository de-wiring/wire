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

    # ResourceFactory creates Resource objects
    # given by name
    class ResourceFactory
      include Singleton

      # given a resource name as a symbol (i.e. :ovsbridge)
      # this creates a resource with given name (i.e. "testbridge")
      def create(resource_symname, *resource_nameargs)
        clazz_map = {
          :ovsbridge => OVSBridge,
          :bridgeip => IPAddressOnIntf
        }
        clazz = clazz_map[resource_symname]
        fail(ArgumentError, "Unknown resource type #{resource_symname}") unless clazz
        clazz.new(*resource_nameargs)
      end
    end
  end
end
