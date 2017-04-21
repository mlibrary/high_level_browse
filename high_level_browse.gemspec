# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'high_level_browse/version'

Gem::Specification.new do |spec|
  spec.name     = "high_level_browse"
  spec.version  = HighLevelBrowse::VERSION
  spec.authors  = ["Bill Dueber"]
  spec.email    = ["bill@dueber.com"]
  spec.summary  = %q{Map LC call numbers to academic categories.}
  spec.homepage = ""
  spec.license  = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'httpclient', "~> 2.5"
  spec.add_dependency 'oga', '>=0.2'
  spec.add_dependency 'lc_callnumber'
  spec.add_dependency 'lcsort'

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
end
