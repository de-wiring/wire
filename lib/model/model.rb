# encoding: utf-8

# Wire module
module Wire
  # define model elements for lookup purposes
  MODEL_ELEMENTS = %w( zones networks )

  # Defines a project with model elements
  # (zones, networks, ...) as open structs
  class Project
    attr_accessor	:target_dir, :data

    # set up empty project
    def initialize(target_dir)
      @target_dir = target_dir
      @data = {}
    end

    # merge in hash data
    def merge_element(element_name, element_data)
      @data.merge!({ element_name.to_sym => element_data })
    end

    # check if we have a model element (i.e. zones)
    def element?(element_name)
      @data.key? element_name.to_sym
    end

    # retrieve element hash, raise ArgumentError if
    # it does not exist.
    def get_element(element_name)
      fail ArgumentError(
           "Element #{element_name} not found"
      ) unless element?(element_name)
      @data[element_name.to_sym]
    end

    # calculates count statistics on project
    def calc_stats
      result = {}
      @data.each do |element_name, element_data|
        result[element_name] = element_data.size
      end
      result
    end
  end

  # ProjectYamlLoader is able to load a model
  # from yaml files (as written by init command)
  class ProjectYamlLoader
    # loads project model from target_dir
    def load_project(target_dir)
      # ensure target dir exists, is a dir

      # create project
      project = Project.new(target_dir)

      MODEL_ELEMENTS.each do |model_element|
        filename = File.join(target_dir, "#{model_element}.yaml")
        element_data = load_model_element_file(filename)
        project.merge_element model_element, element_data
      end

      project
    end

    # reads filename as yaml, returns elements
    def load_model_element_file(filename)
      YAML.load(File.open(filename, 'r'))
    end
  end
end
