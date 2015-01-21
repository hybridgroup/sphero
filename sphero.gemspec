# -*- encoding: utf-8 -*-
Gem::Specification.new do |gem|
  gem.authors       = ["The Hybrid Group"]
  gem.email         = ["sphero@hybridgroup.com"]
  gem.description   = "A ruby gem for controlling your Sphero ball.  Sends commands over the TTY\nprovided by the bluetooth connection."
  gem.summary       = "A ruby gem for controlling your Sphero ball"
  gem.homepage      = "http://github.com/hybridgroup/sphero"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "sphero"
  gem.require_paths = ["lib"]
  gem.version       = "1.5.3"

  gem.add_development_dependency "rake", "~>10.0.4"
  gem.add_development_dependency "mocha", "~>0.13.3"
  gem.add_development_dependency "minitest", "~>5.0.8"

  gem.add_runtime_dependency "rubyserial", ">=0.2.2"
end
