require "socket"
require 'tokaido/bootstrap/piloto'

module Tokaido; end

module Tokaido::Bootstrap
  class HeaderFileChecker
    def symlink_os_x_10_10
      system "ln -sf #{Paths.header_path_for('iconv', '10_10', 'iconv.h')} /usr/include/iconv.h"
      system "ln -sf #{Paths.header_path_for('iconv', '10_10', 'libcharset.h')} /usr/include/libcharset.h"
      system "ln -sf #{Paths.header_path_for('iconv', '10_10', 'localcharset.h')} /usr/include/localcharset.h"
    end

    def symlink_os_x_10_9
      system "ln -sf #{Paths.header_path_for('iconv', '10_9', 'iconv.h')} /usr/include/iconv.h"
      system "ln -sf #{Paths.header_path_for('iconv', '10_9', 'libcharset.h')} /usr/include/libcharset.h"
      system "ln -sf #{Paths.header_path_for('iconv', '10_9', 'localcharset.h')} /usr/include/localcharset.h"
    end

    def symlink_os_x_10_8
      system "ln -sf #{Paths.header_path_for('iconv', '10_8', 'iconv.h')} /usr/include/iconv.h"
      system "ln -sf #{Paths.header_path_for('iconv', '10_8', 'libcharset.h')} /usr/include/libcharset.h"
      system "ln -sf #{Paths.header_path_for('iconv', '10_8', 'localcharset.h')} /usr/include/localcharset.h"
    end

    def symlink_os_x_generic
      system "ln -sf #{Paths.header_path_for('iconv', '', 'iconv.h')} /usr/include/iconv.h"
      system "ln -sf #{Paths.header_path_for('iconv', '', 'libcharset.h')} /usr/include/libcharset.h"
      system "ln -sf #{Paths.header_path_for('iconv', '', 'localcharset.h')} /usr/include/localcharset.h"
    end

    def perform_symlinks(major, minor, tiny)
      begin
        self.send "symlink_os_x_#{[major, minor].join("_")}".to_sym
      rescue
        symlink_os_x_generic
      end
    end
  end
end

module Tokaido::Bootstrap
  class HeaderFileChecker
    def ready(pilot)
      @pilot = pilot
      @pilot.start
    end
  end
end

module Tokaido::Bootstrap
  HeaderFileEnsurancesPiloto.new(HeaderFileChecker.new)      
end

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
        system "sysctl -w net.inet.ip.forwarding=1"
        system "echo \"rdr pass proto tcp from any to any port {80,28561} -> 127.0.0.1 port 28561\" | pfctl -a \"com.apple/250.ApplicationFirewall\" -Ef -"
      elsif line == "disable firewall rules"
        system "pfctl -a com.apple/250.ApplicationFirewall -F all"
      end
    end
  rescue EOFError
  end
end

rescue Exception => e
  puts "#{e.class}: #{e.message}"
  puts e.backtrace
end
