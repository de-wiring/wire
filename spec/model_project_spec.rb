require 'spec_helper'

describe Project do
	
	let(:project) { Project.new(".") }

	subject { project }

	describe 'project' do
		it 'should handle model elements correctly' do
			test_elem = { :key => :elem }
			project.merge_element('test',test_elem)

			project.element?('test').should eq(true)
			project.element?('nonsense').should eq(false)

			project.get_element('test').should eq(test_elem)
			lambda {
				project.get_element('nonsense')
			}.should raise_error
		end

    it 'should calculate statistics correctly' do
      p = Project.new(".")
      p.merge_element(:zones,
                      { 'z1' => { } }
      )
      p.merge_element(:networks,
                      { 'n1' => { :zone => 'z1'} }
      )
      p.calc_stats.should eq({ :zones => 1, :networks => 1})
    end

	end

end


