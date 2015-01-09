# encoding: utf-8

# The MIT License (MIT)
# Copyright (c) 2014 Andreas Schmidt, andreas@de-wiring.net
#

# Wire module
module Wire
  # Run validations on network overlay part (overlays.yaml)
  class OverlaysValidation < ValidationBase
    # run validation steps on overlay elements
    # returns:
    # - nil, results in errors of ValidationBase
    def run_validations
      return unless @project.element?('networks')
      return unless @project.element?('overlays')
      overlays_ok?
      overlays_attached_to_bridges?
      duplicate_overlays_found?
    end

    # ensures that all overlays are attached to a bridge
    def overlays_attached_to_bridges?
      bridges = @project.get_element('networks')

      @project.get_element('overlays').each do |name, data|
        bridge = data[:bridge]
        if !bridge
          mark("overlay #{name} is not attached to a bridge", 'overlays', name)
        else
          mark("overlay #{name} has invalid bridge", 'overlays', name) unless bridges.key?(bridge)
        end
      end
    end

    # ensures that all fields are valid
    def overlays_ok?
      @project.get_element('overlays').each do |name, data|
        type = data[:type]
        if !type || (type && type.size == 0)
          mark("overlay #{name} is missing a :type", 'overlays', name)
        else
          supported_types = %w(vxlan)
          if !supported_types.include?(type)
            mark("overlay #{name} has unsupported missing :type", 'overlays', name)
          end
        end

        remote = data[:remote]
        if !remote || (remote && remote.size == 0)
          mark("overlay #{name} is missing a :remote endpoint", 'overlays', name)
        else
          # TODO: check if :ip is an ip
        end
      end
    end

    # ensures that all overlay ips,types,remotes are unique
    def duplicate_overlays_found?
      dup_map = {}
      @project.get_element('overlays').each do |ov_name, ov_data|
        # nw = ov_data[:network]
        # dupe_name = dup_map[nw]
        #
        # mark("Network range #{nw} used in more than one network (#{dupe_name})",
        #      'network', network_name) if dupe_name
        # dup_map.store nw, network_name
      end
    end
  end
end
