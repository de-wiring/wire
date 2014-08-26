require 'spec_helper.rb'

describe 'It should have fig installed' do
	describe command 'sudo pip list' do
		its(:stdout) { should match /^fig/ }
	end

	describe command 'sudo /usr/local/bin/fig --version' do
		its(:stdout) { should match /^fig/ }
	end
end


