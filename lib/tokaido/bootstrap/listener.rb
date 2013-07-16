require "tokaido/bootstrap/protocol"
require "muxr/application"
require "socket"

Thread.abort_on_exception = true

module Tokaido
  module Bootstrap
    class Listener
      def initialize(manager, server)
        @manager = manager
        @server = server
        @protocol = Protocol.new("tokaido")
        @apps = {}

        @stopped = false
      end

      def listen
        Thread.new { listen_for_requests }
      end

      def stop
        @server.close
      end

      def respond(string)
        print_to_socket(string)
      end

      def process_request(line, socket=nil)
        query = @protocol.decode(line)

        if query.error?
          print_to_socket query.reason
        else
          handle_query(query)
        end
      end

      def failed(app)
        @manager.remove_app(app, respond: false)
        respond(%{ERR "#{app.host}" failed})
      end

    private
      def print_to_socket(msg)
        @socket.puts msg if @socket
        puts msg
      end

      def listen_for_requests
        @socket = @server.accept
        print_to_socket "TOKAIDO ACTIVE"

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
        { host: query.host, port: find_server_port, out: out(query), err: err(query), delegate: self }
      end

      def handle_query(query)
        case query.type
        when "ADD"
          app = Muxr::Application.new(query.directory, app_params(query))
          @apps[query.host] = app
          @manager.add_app app
        when "REMOVE"
          app = @apps[query.host]
          @manager.remove_app app
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
