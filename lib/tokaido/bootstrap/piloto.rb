module Tokaido
  module Bootstrap
    module Paths
      STATIC_BUILDS = File.expand_path(File.join("..", "..", "..", "..", "..", "Gems", "supps"), __FILE__)
      ICONV = File.join(STATIC_BUILDS, "iconv")

      def self.header_path_for(libname, os, h_file)
        begin
          src = Paths.const_get(libname.upcase.to_sym)
          File.join(src, os, "include", h_file)
        rescue
          ""
        end        
      end
    end

    class GemExtensioner
      def initialize(builder)
        @builder = builder
        @builder.ready(self)
      end  

      def flags_for(given_gem)
        ""
      end
    end

    module Piloto
      def initialize(worker)
        @worker = worker
        @worker.ready(self)
      end

      def mac_info
        `sw_vers -productVersion`.chomp.split('.').map(&:to_i)
      end
    end
 
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

    class HeaderFileEnsurancesPiloto
      include Piloto
   
      def start
        @worker.perform_symlinks(*mac_info)
      end
    end

    class InstallerPiloto
      include Piloto
      include FirewallOptions 

      def start
        @worker.done if File.exists?(firewall_destination)
        @worker.write_resolver
        @worker.copy_firewall_rules
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
