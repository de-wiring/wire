# encoding: utf-8

module Wire

	class ValidationError
		attr_accessor	:message, :element_type, :element_name

		def initialize(message,element_type,element_name)
			@message = message
			@element_type = element_type
			@element_name = element_name
		end

		def to_s
			"ValidationError on #{@element_type} #{@element_name} : #{@message}"
		end
	end

	class ValidationBase

		attr_accessor	:errors

		def initialize(project)
			@project = project
			@errors = []
		end

		def mark(message,element_type,element_name)
			@errors << ValidationError.new(message,element_type,element_name)
		end
	end

	class NetworksValidation < ValidationBase
		def run_validations
			networks_attached_to_zones?
		end

		def networks_attached_to_zones?
			zones = @project.get_element('zones')
			@project.get_element('networks').each do |network_name, network_data|
				zone = network_data[:zone]
				type = 'network'
				name = network_name
				unless zone
					mark('Network is not attached to a zone',type,name)
				else
					unless zones.has_key?(zone)
						mark('Network has invalid zone',type,name)
					end
				end
			end
		end

	end

		
end

