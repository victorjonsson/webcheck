# -*- encoding: utf-8 -*-

$:.unshift(File.join(File.dirname(__FILE__), "/lib"))
require 'webcheck'

Gem::Specification.new do |s|
  s.name        = "webcheck"
  s.version     = WebCheck::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Victor Jonsson"]
  s.email       = ["kontakt@victorjonsson.se"]
  s.homepage    = "http://victorjonsson.se"
  s.summary     = %q{Check your website man!}
  s.description = %q{Just check it!}

  s.required_ruby_version     = '>= 1.9.3'

  s.add_dependency "httparty", "~> 0.12.0"

  s.post_install_message = "Just check it!"

  s.files         = `git ls-files`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end