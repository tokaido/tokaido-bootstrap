require "socket"

begin

tmp = ENV["TOKAIDO_TMPDIR"]

socket = "#{tmp}/firewall.sock"
out = "#{tmp}/firewall.out"
err = "#{tmp}/firewall.err"

# Redirect stdout and stderr to log files
STDOUT.reopen(out)
STDERR.reopen(err)

begin
  server = UNIXServer.open(socket)
rescue Errno::EADDRINUSE
  File.delete(socket)
  retry
end

# Allow userland programs to write to this
File.chmod(766, socket)

# When this program exits, clean up the socket
at_exit do
  server.close
  File.delete(socket)
end

puts "Tokaido Active!"

while true
  begin
    # Listen on the socket
    s = server.accept

    # Support two commands: "enable firewall rules" and "disable firewall rules"
    # Use rule 28561 so we can find and delete it later
    while line = s.readline.chomp
      if line == "enable firewall rules"
        system "ipfw add 28561 fwd 127.0.0.1, 28561 tcp from any to me dst-port 80 in && sysctl -w net.inet.ip.forwarding=1"
      elsif line == "disable firewall rules"
        system "ipfw del 28561"
      end
    end
  rescue EOFError
  end
end

rescue Exception => e
  puts "#{e.class}: #{e.message}"
  puts e.backtrace
end
