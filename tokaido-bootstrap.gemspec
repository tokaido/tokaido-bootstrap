# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tokaido/bootstrap/version'

Gem::Specification.new do |gem|
  gem.name          = "tokaido-bootstrap"
  gem.version       = Tokaido::Bootstrap::VERSION
  gem.authors       = ["Yehuda Katz"]
  gem.email         = ["wycats@gmail.com"]
  gem.description   = %q{Entry point for the Tokaido GUI}
  gem.summary       = %q{Bundles dns resolver and muxr}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency "muxr"
  gem.add_dependency "tokaido-dns"

  gem.add_development_dependency "rspec"
  gem.add_development_dependency "simplecov"
end
