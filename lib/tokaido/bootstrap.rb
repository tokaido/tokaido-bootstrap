require "tokaido/bootstrap/version"
require "tokaido/bootstrap/protocol"
require "tokaido/bootstrap/manager"
require "tokaido/bootstrap/listener"

module Tokaido
  module Bootstrap
    def self.boot(tmpdir)
      @stopped = false
      @mutex = Mutex.new

      muxr_socket = File.join(tmpdir, "muxr.sock")
      log_socket = File.join(tmpdir, "log.sock")
      firewall_socket = File.join(tmpdir, "firewall.sock")

      @manager = Tokaido::Bootstrap::Manager.new(muxr_socket, firewall_socket, tmpdir)
      @manager.enable

      at_exit { stop }

      STDIN.each do |line|
        @manager.process_request line
      end

      sleep
    rescue Interrupt
      # graceful ctrl-c is handled by the above at_exit hook, so don't do anything
    end

    def self.stop
      @manager.stop
    end
  end
end

