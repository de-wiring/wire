# Encoding: utf-8
#
# #require "bundler/gem_tasks"
require 'rake/testtask'
require 'rubocop/rake_task'

desc "Run rubycritic on code"
task :critic do
	system 'rubycritic lib'
end

desc "Run rubocop to lint code"
task :lint do
  system 'rubocop -l lib'
end

desc "Run rubocop"
RuboCop::RakeTask.new(:rubocop)

desc "Run rspec tests"
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

