# encoding: utf-8

module Wire
	module Resource
	
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

