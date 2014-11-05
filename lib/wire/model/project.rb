# encoding: utf-8

# The MIT License (MIT)
# Copyright (c) 2014 Andreas Schmidt, andreas@de-wiring.net
#

# Wire module
module Wire
  # define model elements for lookup purposes
  MODEL_ELEMENTS = %w( zones networks appgroups )

  # Defines a project with model elements
  # (zones, networks, ...) as open structs
  class Project
    # +target_dir+ is the directory where model files are stores
    # +data+ is a [Hash] of all model objects
    attr_accessor	:target_dir, :data

    # set up empty project. Sets +target_dir+
    def initialize(target_dir)
      @target_dir = target_dir
      @data = {}
    end

    # merge in hash data
    # Params:
    # +element_name+ Name of model element part, i.e. 'zones'
    # +element_data+ [Hash] of model element data
    def merge_element(element_name, element_data)
      @data.merge!({ element_name.to_sym => element_data })
    end

    # check if we have a model element (i.e. zones)
    # params:
    # +element_name+ Name of model element part, i.e. 'backend-zone'
    def element?(element_name)
      @data.key? element_name.to_sym
    end

    # retrieve element hash, raise ArgumentError if
    # it does not exist.
    # params:
    # +element_name+ Name of model element part, i.e. 'backend-zone'
    def get_element(element_name)
      fail(
          ArgumentError, "Element #{element_name} not found"
      ) unless element?(element_name)
      @data[element_name.to_sym]
    end

    # return project's var/tmp directory, will be configurable
    # in the future
    def vartmp_dir
      # as of now, use .state in target dir
      state_dir = File.join(@target_dir, '.state')
      unless File.directory? state_dir
        FileUtils.mkdir_p state_dir
        $log.debug "created state dir #{state_dir}"
      end
      state_dir
    end

    # calculates count statistics on project
    # returns:
    # - [Hash], key => element type, value => [int] count
    def calc_stats
      result = {}

      @data.each do |element_name, element_data|
        result[element_name] = element_data.size
      end

      result
    end
  end
end
