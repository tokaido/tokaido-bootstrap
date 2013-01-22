require "tokaido/bootstrap/version"
require "tokaido/bootstrap/protocol"
require "tokaido/bootstrap/manager"
require "tokaido/bootstrap/listener"

module Tokaido
  module Bootstrap
    def self.boot(tmpdir)
      muxr_socket = File.join(tmpdir, "muxr.sock")
      log_socket = File.join(tmpdir, "log.sock")

      @manager = Tokaido::Bootstrap::Manager.new(muxr_socket, log_socket, nil)
      @manager.enable

      setup_traps

      sleep
    end

    def self.setup_traps
      puts "Enabling traps"
      trap(:TERM) { stop }
      trap(:INT) { stop }
    end

    def self.stop
      @manager.stop
    end
  end
end

