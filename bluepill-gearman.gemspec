# -*- encoding: utf-8 -*-
require File.expand_path('../lib/bluepill-gearman/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Ami Mahloof"]
  gem.email         = ["ami.mahloof@gmail.com"]
  gem.description   = %q{send events to gearman when a bluepill process state changes}
  gem.summary       = %q{send events to gearman via the send_gearman when a bluepill monitored process triggers a state change}
  gem.homepage      = "https://github.com/gtforge/bluepill-gearman"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.name          = "bluepill-gearman"
  gem.require_paths = ["lib"]
  gem.add_dependency "bluepill"
  gem.add_dependency "gearman-ruby"
  #gem.add_dependency "crypt"
  gem.add_development_dependency "minitest"
  gem.add_development_dependency "mocha"
  gem.add_development_dependency "yard"
  gem.add_development_dependency "redcarpet"
  gem.version       = Bluepill::Gearman::VERSION
end
