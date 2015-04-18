module Tokaido
  module Bootstrap
    class Request
      attr_reader :type, :directory, :host, :port

      def initialize(type, directory, host, port)
        @type, @directory, @host, @port = type, directory, host, port
      end

      def error?
        false
      end
    end

    class Stop
      attr_reader :type

      def initialize
        @type = "STOP"
      end

      def error?
        false
      end
    end

    class Error
      INVALID = "INVALID"

      attr_reader :reason

      def initialize(host, reason = nil)
        if host.nil?
          @reason = INVALID
        else
          @reason = %{ERR "#{host}" #{reason}}
        end
      end

      def error?
        true
      end
    end

    class Protocol
      ADD = "ADD"
      ADD_MATCH = /^(ADD) "([^"]+)" "([^"]+)"\ ?([0-9]+)?/
      REMOVE = "REMOVE"
      REMOVE_MATCH = /^(REMOVE) "([^"]+)"$/
      INVALID_HOST = "invalid-host"
      INVALID_DIRECTORY = "dir-not-found"

      def initialize(domain)
        @domain_ending = ".#{domain}"
        @error = false
        @error_reason = nil
      end

      def decode(string)
        if string.chomp == "STOP"
          return Stop.new
        end

        match = string.match(ADD_MATCH) || string.match(REMOVE_MATCH)

        return Error.new(nil) if match.nil?

        _, type, directory, host, port = match.to_a

        if !valid_host?(host)
          Error.new(host, INVALID_HOST)
        elsif type == "ADD" && !valid_directory?(directory)
          Error.new(host, INVALID_DIRECTORY)
        else
          Request.new(type, directory, host, port)
        end
      end

      def error?
        @error
      end

    private
      def error!(reason=nil)
        @error = true
        @error_reason = reason
      end

      def valid_host?(host)
        host.end_with?(@domain_ending)
      end

      def valid_directory?(directory)
        absolute = File.expand_path(directory) == directory
        absolute && File.directory?(directory)
      end
    end
  end
end
