# encoding: utf-8

# Wire module
module Wire
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
        $log.debug "Loading model file #{filename}"

        element_data = load_model_element_file(filename)
        project.merge_element model_element, element_data
      end

      # dump some statistics
      puts(project.calc_stats.reduce([]) do |res, elem|
        type = elem[0]
        count = elem[1]
        res << "#{count} #{type}(s)"
      end.join(', '))

      project
    end

    # reads filename as yaml, returns elements
    def load_model_element_file(filename)
      YAML.load(File.open(filename, 'r'))
    end
  end
end
