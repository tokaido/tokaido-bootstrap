module Tokaido
  module Bootstrap

    module FirewallOptions
      def firewall_destination
        "/Library/LaunchDaemons/com.tokaido.firewall.plist"
      end

      def firewall_source
        File.expand_path(File.join("..", "..", "..", "..", "firewall", "com.tokaido.firewall.plist"), __FILE__)
      end

      def resolver_content
        ["/etc/resolver/tokaido", "Generated for Tokaido\nnameserver #{nameserver}\nport #{port}"]
      end

      def nameserver
        "127.0.0.1"
      end

      def port
        30405
      end
    end

    class BootstrapInstaller
      include FirewallOptions 

      def initialize(worker)
        @worker = worker
        @worker.ready(self)
      end

      def mac_info
        `sw_vers -productVersion`.chomp.split('.').map(&:to_i)
      end

      def start
        @worker.done if File.exists?(firewall_destination)
        @worker.write_resolver
        @worker.copy_firewall_rules

        load_jobs

        @worker.done
      end

      def load_jobs
        major, minor, _ = mac_info

        case
          when minor >= 10 then @worker.load_yosemite_and_forward
          else; @worker.load_before_yosemites
        end
      end
    end
  end
end
