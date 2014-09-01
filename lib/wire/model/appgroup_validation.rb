# encoding: utf-8

# The MIT License (MIT)
# Copyright (c) 2014 Andreas Schmidt, andreas@de-wiring.net
#

# Wire module
module Wire
  # Run validations on appgroup model part
  class AppGroupValidation < ValidationBase
    # run validation steps on appgroup elements
    # returns
    # - nil, results in errors of ValidationBase
    def run_validations
      return unless @project.element?('appgroups')

      appgroups_attached_to_zones?
      controllers_valid?
    end

    # ensures that all application groups are attached to a zone
    def appgroups_attached_to_zones?
      objects_attached_to_zones? 'appgroups'
    end

    # ensures that all application groups have a known controller
    def controllers_valid?
      @project.get_element('appgroups').each do |appgroup_name, appgroup_data|
        controller_data = appgroup_data[:controller]
        type = 'appgroup'
        name = appgroup_name
        if !controller_data
          mark('Appgroup is not attached to a zone', type, name)
        else
          type = controller_data[:type]
          mark('Appgroup controller does not have a type', type, name) unless type && type.size > 0

          known_types = %w(fig)
          mark('Appgroup controller has an unkown type (#{type})',
               type, name) unless known_types.include?(type)
        end
      end
    end
  end
end
