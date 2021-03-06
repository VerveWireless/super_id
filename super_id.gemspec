# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'super_id/version'

Gem::Specification.new do |spec|
  spec.name          = "super_id"
  spec.version       = SuperId::VERSION
  spec.authors       = ["Jeff Cooper"]
  spec.email         = ["jeff.cooper@vervemobile.com"]
  spec.summary       = %q{Disguise your model ID’s when displayed in the UI or API}
  #spec.description   = %q{Write a longer description. Optional.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.3"
  spec.add_development_dependency "guard-rspec", "~> 4.5"
  spec.add_development_dependency "rails", "~> 4.2.2"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-nav"

  spec.add_runtime_dependency "hashids", "~> 1.0"
end
