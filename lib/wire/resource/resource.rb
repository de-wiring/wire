# encoding: utf-8

# The MIT License (MIT)
# Copyright (c) 2014 Andreas Schmidt, andreas@de-wiring.net
#

# Wire module
module Wire
  # Resource module
  module Resource
    # ResourceBase is the base class for all
    # resource elements
    class ResourceBase
      # +name+ of the resource
      attr_accessor	:name

      # initializes base with given +name+
      def initialize(name)
        @name = name
      end

      # returns string representation
      def to_s
        "Resource:[#{name}]"
      end
    end

    # ResourceFactory creates Resource objects
    # given by name
    class ResourceFactory
      include Singleton

      # given a +resource_name+ as a symbol (i.e. :ovsbridge)
      # this creates a resource with given name (i.e. "testbridge")
      # and hands on arguments (+resource_nameargs+, may be 1..n)
      # returns
      # - a new Resource object, depending on type
      def create(resource_symname, *resource_nameargs)
        clazz_map = {
          :ovsbridge  => OVSBridge,
          :bridgeip   => IPAddressOnIntf,
          :dhcpconfig => DHCPRangeConfiguration,
          :figadapter => FigAdapter
        }
        clazz = clazz_map[resource_symname]
        fail(ArgumentError, "Unknown resource type #{resource_symname}") unless clazz
        clazz.new(*resource_nameargs)
      end
    end
  end
end
