require "tokaido/bootstrap/protocol"
require "muxr/application"

module Tokaido
  module Bootstrap
    class Listener
      def initialize(manager, server)
        @manager = manager
        @server = server
        @protocol = Protocol.new("tokaido")

        @stopped = false
      end

      def listen
        puts "Enabled Tokaido Bootstrap Listener"
        Thread.new { listen_for_requests }
      end

      def stop
        puts "Shut Down Tokaido Bootstrap Listener"
        @server.close
      end

      def respond(string)
        @socket.puts string
      end

    private
      def listen_for_requests
        @socket = @server.accept

        while line = @socket.readline.chomp
          p line
          query = @protocol.decode(line)

          if query.error?
            puts query.reason
            @socket.puts query.reason
          else
            handle_query(query)
          end
        end
      end

      def handle_query(query)
        case query.type
        when "ADD"
          @manager.add_app Muxr::Application.new(query.directory, port: query.port, host: query.host)
        when "REMOVE"
          raise
        when "STOP"
          @manager.stop
        end
      end
    end
  end
end
