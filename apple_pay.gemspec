$LOAD_PATH.push File.expand_path("../lib", __FILE__)
require 'apple_pay/version'

Gem::Specification.new do |s|
  s.name              = "apple_pay"
  s.version           = ApplePay::VERSION
  s.platform          = Gem::Platform::RUBY
  s.author            = "Mark Bennett"
  s.email             = ["mark@spreedly.com"]
  s.homepage          = "https://github.com/spreedly/apple_pay"
  s.summary           = "Apple Pay token decryption library"
  s.description       = "Given an (encrypted) Apple Pay token, verify and decrypt it"

  s.rubyforge_project = "apple_pay"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.required_ruby_version = ">= 1.8.7"

  s.add_runtime_dependency 'aead'
end
