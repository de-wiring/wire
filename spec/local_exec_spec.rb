require 'spec_helper'

include Wire::Execution

describe LocalExecution do

  it 'should construct a simple command correctly' do
    cmd = 'echo HelloWorld'
    e = LocalExecution.new(cmd,nil,{ :b_sudo => false, :b_shell => false })

    e.get_command.should eq(cmd)
  end

  it 'should construct a simple command with sudo correctly' do
    cmd = 'echo HelloWorld'
    e = LocalExecution.new(cmd,nil,{ :b_sudo => true, :b_shell => false })

    e.get_command.should eq("sudo #{cmd}")
  end

  it 'should construct a simple command with shell option correctly' do
    cmd = 'echo HelloWorld'
    e = LocalExecution.new(cmd,nil,{ :b_sudo => false, :b_shell => true })

    e.get_command.should eq("/bin/sh -c '#{cmd}'")
  end

  it 'should construct a simple command with shell and sudo option correctly' do
    cmd = 'echo HelloWorld'
    e = LocalExecution.new(cmd,nil,{ :b_sudo => true, :b_shell => true })

    e.get_command.should eq("/bin/sh -c 'sudo #{cmd}'")
  end

  it 'should construct a complex command correctly' do
    cmd = 'echo'
    args = [ 'Hello', 'World', '| wc -l']
    e = LocalExecution.new(cmd,args,{ :b_sudo => false, :b_shell => false })

    e.get_command.should eq('echo Hello World | wc -l')
  end

  it 'should construct a complex command with sudo correctly' do
    cmd = 'echo'
    args = [ 'Hello', 'World', '| wc -l']
    e = LocalExecution.new(cmd,args,{ :b_sudo => true, :b_shell => false })

    e.get_command.should eq('sudo echo Hello World | wc -l')
  end

  it 'should construct a complex command with shell option correctly' do
    cmd = 'echo'
    args = [ 'Hello', 'World', '| wc -l']
    e = LocalExecution.new(cmd,args,{ :b_sudo => false, :b_shell => true })

    e.get_command.should eq('/bin/sh -c \'echo Hello World | wc -l\'')
  end

  it 'should construct a complex command with sudo and shell option correctly' do
    cmd = 'echo'
    args = [ 'Hello', 'World', '| wc -l']
    e = LocalExecution.new(cmd,args,{ :b_sudo => true, :b_shell => true })

    e.get_command.should eq('/bin/sh -c \'sudo echo Hello World | wc -l\'')
  end


end
