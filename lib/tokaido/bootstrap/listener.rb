require "tokaido/bootstrap/protocol"
require "muxr/application"
require "socket"

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
        @socket.puts string if @socket
        puts string
      end

      def process_request(line, socket=nil)
        query = @protocol.decode(line)

        if query.error?
          puts query.reason
          @socket.puts query.reason if socket
        else
          handle_query(query)
        end
      end

    private
      def listen_for_requests
        @socket = @server.accept

        while line = @socket.readline.chomp
          process_request(line, @socket)
        end
      end

      def out(query)
        File.join(@manager.tmpdir, "#{query.host}.out")
      end

      def err(query)
        File.join(@manager.tmpdir, "#{query.host}.err")
      end

      def app_params(query)
        { host: query.host, port: find_server_port, out: out(query), err: err(query) }
      end

      def handle_query(query)
        case query.type
        when "ADD"
          @manager.add_app Muxr::Application.new(query.directory, app_params(query))
        when "REMOVE"
          raise
        when "STOP"
          # This will trigger an at_exit hook that shuts down the applications
          exit
        end
      end

      PORT_RANGE = (20000..40000).to_a

      def find_server_port
        port_attempt = PORT_RANGE.sample
        socket = TCPServer.new("0.0.0.0", port_attempt)
        return port_attempt
      rescue Errno::EADDRINUSE
        retry
      ensure
        socket.close if socket
      end
    end
  end
end
