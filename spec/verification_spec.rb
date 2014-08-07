require 'spec_helper'

describe VerificationError do

  it 'should display VerificationErrors correctly' do
    error = VerificationError.new 'FooMessage', 'FooType', 'FooObject', Object.new
    error.to_s.should eq('VerificationError on FooType FooObject : FooMessage')
  end
end

# describe VerifyCommand do
#   it 'should not yield errors on correct sample project' do
#     p = Project.new(".")
#     p.merge_element(:zones,
#                     { 'z1' => { } }
#     )
#     p.merge_element(:networks,
#                     { 'n1' => { :zone => 'z1'} }
#     )
#
#     vc = VerifyCommand.new
#     vc.project = p
#     vc.run_on_project
#
#     vc.findings.size.should eq(0)
#   end
# end


