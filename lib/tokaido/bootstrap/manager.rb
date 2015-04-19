require "muxr"
require "tokaido-dns"
require "socket"

module Tokaido
  module Bootstrap
    class Manager
      attr_reader :tmpdir

      def initialize(muxr_socket, firewall_socket, tmpdir)
        @muxr_socket = muxr_socket
        @firewall_socket = firewall_socket
        @tmpdir = tmpdir
      end

      def enable
        @muxr_commands_server = connect_server(@muxr_socket)
        @firewall_client = connect_client(@firewall_socket)

        boot_dns
        boot_muxr

        enable_firewall_rules
        listen_for_commands
      end

      def process_request(line)
        @listener.process_request(line)
      end

      def stop
        stop_dns
        stop_muxr
        disable_firewall_rules
        unlisten_for_commands
      end

      MESSAGES = {
        unavailable_port: %{ERR "%{host}" port},
        dup_host:         %{DUP "%{host}" host},
        dup_dir:          %{DUP "%{host}" directory},
        added:            %{ADDED "%{host}"},
        removed:          %{REMOVED "%{host}"}
      }

      def add_app(application)
        params = { host: application.host }
        response = @apps.add application, self

        @listener.respond(MESSAGES[response] % params)
      end

      def remove_app(application, options={ respond: true })
        p application.pid
        response = @apps.remove application

        if options[:respond]
          params = { host: application.host }
          @listener.respond(MESSAGES[response] % params)
        end
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
        begin
          UNIXSocket.new(socket)
        rescue Errno::ENOENT, Errno::EACCES
          retry
        end
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
        @firewall_client.puts "enable firewall rules"
      end

      def disable_firewall_rules
        @firewall_client.puts "disable firewall rules"
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
