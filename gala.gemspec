# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gala/version'

Gem::Specification.new do |spec|
  spec.name              = "gala"
  spec.version           = Gala::VERSION
  spec.authors           = ["Mark Bennett", "Ryan Daigle"]
  spec.email             = ["ryan@spreedly.com"]

  spec.summary           = "Apple Pay payment token decryption library"
  spec.description       = "Given an (encrypted) Apple Pay token, verify and decrypt it"
  spec.homepage          = "https://github.com/spreedly/gala"
  spec.license           = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test)/}) }
  spec.test_files    = `git ls-files -- test/*`.split("\n")
  spec.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.6.0'

  spec.add_runtime_dependency 'openssl', '3.1.0'

  spec.add_development_dependency 'bundler', '~> 1.14'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'minitest'
end
