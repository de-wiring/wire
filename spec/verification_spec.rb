require 'spec_helper'

describe VerificationError do

  it 'should display VerificationErrors correctly' do
    error = VerificationError.new 'FooMessage', 'FooType', 'FooObject', Object.new
    error.to_s.should eq('VerificationError on FooType FooObject : FooMessage')
	end
end


