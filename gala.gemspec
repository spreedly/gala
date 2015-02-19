$LOAD_PATH.push File.expand_path("../lib", __FILE__)
require 'gala/version'

Gem::Specification.new do |s|
  s.name              = "gala"
  s.version           = Gala::VERSION
  s.platform          = Gem::Platform::RUBY
  s.authors           = ["Mark Bennett", "Ryan Daigle"]
  s.email             = ["ryan@spreedly.com"]
  s.homepage          = "https://github.com/spreedly/gala"
  s.summary           = "Apple Pay payment token decryption library"
  s.description       = "Given an (encrypted) Apple Pay token, verify and decrypt it"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.required_ruby_version = ">= 1.8.7"

  s.add_runtime_dependency 'aead'
end
