require "muxr"
require "tokaido-dns"
require "socket"

module Tokaido
  module Bootstrap
    class Manager
      def initialize(muxr_socket, logger_socket, firewall_socket)
        @muxr_socket = muxr_socket
        @logger_socket = logger_socket
        @firewall_socket = firewall_socket
      end

      def enable
        puts "Enabling Tokaido Bootstrap Manager"

        @muxr_commands_server = connect_server(@muxr_socket)
        @logger_server = connect_server(@logger_socket)
        #@firewall_client = connect_client(@firewall_socket)

        boot_dns
        boot_muxr

        enable_firewall_rules
        listen_for_commands
      end

      def stop
        puts "Stopping Tokaido Bootstrap Manager"
        
        stop_dns
        stop_muxr
        disable_firewall_rules
        unlisten_for_commands

        exit
      end

      def add_app(application)
        @apps.add application
      end

      def remove_app(application)
        @apps.remove application
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
        @dns_server = Tokaido::DNS::Server.new(9439)
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
      end

      def disable_firewall_rules
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
