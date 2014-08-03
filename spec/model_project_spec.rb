require 'spec_helper'

describe Project do
	
	let(:project) { Project.new(".") }

	subject { project }

	describe 'project' do
		it 'should handle model elements correctly' do
			test_elem = { :key => :elem }
			project.merge_element('test',test_elem)

			project.has_element('test').should eq(true)
			project.has_element('nonsense').should eq(false)

			project.get_element('test').should eq(test_elem)
			lambda {
				project.get_element('nonsense')
			}.should raise_error
		end

	end

end


