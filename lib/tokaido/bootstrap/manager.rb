require "muxr"
require "tokaido-dns"
require "socket"

module Tokaido
  module Bootstrap
    class Manager
      attr_reader :tmpdir

      def initialize(muxr_socket, firewall_socket, tmpdir)
        @muxr_socket = muxr_socket
        @firewall_socket = UNIXSocket.new(firewall_socket)
        @tmpdir = tmpdir
      end

      def enable
        puts "Enabling Tokaido Bootstrap Manager"

        @muxr_commands_server = connect_server(@muxr_socket)

        boot_dns
        boot_muxr

        enable_firewall_rules
        listen_for_commands
      end

      def process_request(line)
        @listener.process_request(line)
      end

      def stop
        puts "Stopping Tokaido Bootstrap Manager"

        stop_dns
        stop_muxr
        disable_firewall_rules
        unlisten_for_commands
      end

      MESSAGES = {
        unavailable_port: %{ERR "%{host}" port},
        dup_host:         %{DUP "%{host}" host},
        dup_dir:          %{DUP "%{host}" directory},
        added:            %{ADDED "%{host}"}
      }

      def add_app(application)
        params = { host: application.host }
        response = @apps.add application, self

        @listener.respond(MESSAGES[response] % params)
      end

      def remove_app(application)
        @apps.remove application
      end

      def app_booted(application)
        @listener.respond %{READY "#{application.host}"}
      end

    private
      def connect_server(socket)
        begin
          UNIXServer.open(socket)
        rescue Errno::EADDRINUSE
          File.delete(socket)
          retry
        end
      end

      def connect_client(socket)
        # TODO Error handling
        UNIXSocket.open(socket)
      end

      def boot_dns
        @dns_server = Tokaido::DNS::Server.new(30405)
        @dns_server.start
      end

      def stop_dns
        @dns_server.stop
      end

      def boot_muxr
        @apps = Muxr::Apps.new
        @muxr_server = Muxr::Server.new(@apps, port: 28561)
        @muxr_server.boot
      end

      def stop_muxr
        @muxr_server.stop
      end

      def enable_firewall_rules
        @firewall_socket.puts "enable firewall rules"
      end

      def disable_firewall_rules
        @firewall_socket.puts "disable firewall rules"
      end

      def listen_for_commands
        @listener = Listener.new(self, @muxr_commands_server)
        @listener.listen
      end

      def unlisten_for_commands
        @listener.stop
      end
    end
  end
end
