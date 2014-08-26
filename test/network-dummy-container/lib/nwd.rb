#!/usr/bin/env ruby

# network dummy
# - listen on defined interface/port
# - upon receiving a tcp request, pings other services
# - auto-ping other services at regular intervals
# Log output
# . = incoming request, C=outgoing request by cron
# A = outgoing request by action (-a)
# X = error when making outgoing "C" call
# Y = error when making outgoing "A" call

require 'tempfile'
require 'optparse'
require 'socket'

options = {}
options[:cronping] = []
options[:ping] = []

optparse = OptionParser.new do |opts|

  options[:listen_intf] = nil
  opts.on( '-i', '--intf DEVICE', 'Interface to listen on, i.e. eth1' ) do |e|
    options[:listen_intf] = e
  end

  options[:listen_port] = nil
  opts.on( '-p', '--port PORT', 'Port to listen on' ) do |e|
    options[:listen_port] = e
  end

  options[:logpath] = nil
  opts.on( '-l', '--log DIR', 'Log output to a file in DIR (default: stdout)' ) do |e|
    options[:logpath] = e
  end

  opts.on( '-c', '--cron SPEC', 'ping another service at regular intervals. SPEC=<WAITSECS>:<HOST>:<PORT>' ) do |e|
    a = e.split(':')
    options[:cronping] << { :wait => a[0].to_i, :ip => a[1], :port => a[2].to_i }
  end

  opts.on( '-a', '--action SPEC', 'upon receiving a ping, ping another service. SPEC=<WAITSECS>:<HOST>:<PORT>' ) do |e|
    a = e.split(':')
    options[:ping] << { :wait => a[0].to_i, :ip => a[1], :port => a[2].to_i }
  end

end


optparse.parse!
#pp options

if (options[:listen_intf] && options[:listen_intf].size >= 0) then
 if options[:listen_port].nil? || (options[:listen_port] && options[:listen_port].size == 0) then
   STDERR.puts  'Must support listen port using -p when in listen mode  '
   STDOUT.puts optparse
   exit 2
 end
end


# set up logging target
$log_out = STDOUT
if options[:logpath]
  logfile = File.join(options[:logpath],`hostname -s`)
  $log_out.puts "Writing log to #{logfile}"
  $log_out = open(logfile,'w+')
end

# set up cronping thread
sec_count = 0
Thread.start {
  loop do
    begin
      entries = options[:cronping]
      entries.each do |e|
        # ping the other service
        if sec_count % e[:wait] == 0 then
          $log_out.print "C"
          TCPSocket.open(e[:ip],e[:port]) do |x|
            x.puts "EHLO"
          end
        end
      end

    rescue => e
      $log_out.print "X"
    end

    sleep 1
    sec_count += 1
  end
}


# wait for carrier on given interface
if options[:listen_intf] && options[:listen_intf].size > 0
  b_carrier = false
  while !b_carrier do
    fname = "/sys/class/net/#{options[:listen_intf]}/carrier"
    begin
      open(fname,'r') do |f|
       l = f.read
       if l && l.chomp == "1"
         b_carrier = true
         break
       else
         sleep 1
       end
      end
    rescue
    end
  end
  $log_out.puts "Got carrier on #{options[:listen_intf]}"

  # get ip address of given interface
  cmd = "ip addr show #{options[:listen_intf]}"
  re_ip = /^.*inet (.*)\/.*/
  ip = nil
  `#{cmd}`.chomp.strip.split("\n").each do |line|
    md = line.match re_ip
    ip = md[1] if md && md.size > 1
  end

  $log_out.puts "IP of #{options[:listen_intf]} is #{ip}"

  # open tcp socket, listen on it
  server = TCPServer.open(ip,options[:listen_port])
  loop do
    Thread.start(server.accept) do |client|
      while line = client.gets
        $log_out.print '.'
        $log_out.flush

        if line.chomp.strip == 'quit'
          client.close
          exit 0
        end

        # spawn pings..
        options[:ping].each do |e|
          Thread.start {
            sleep e[:wait]
            begin
              $log_out.print "A"
              TCPSocket.open(e[:ip],e[:port]) do |x|
                x.puts "HELO"
              end
            rescue
              $log_out.print "Y"
            end
          }
        end

      end
      client.close
    end
  end
else
  # not listening, so loop forever
  loop do
    sleep 1
  end
end



