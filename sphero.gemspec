# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "sphero"
  s.version = "1.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Hybrid Group"]
  s.date = "2013-07-25"
  s.description = "A ruby gem for controlling your Sphero ball.  Sends commands over the TTY\nprovided by the bluetooth connection."
  s.email = ["sphero@hybridgroup.com"]
  s.executables = ["sphero"]
  s.extra_rdoc_files = ["CHANGELOG.rdoc", "Manifest.txt", "CHANGELOG.rdoc", "README.markdown"]
  s.files = [".autotest", "CHANGELOG.rdoc", "Manifest.txt", "README.markdown", "Rakefile", "bin/sphero", "lib/sphero.rb", "lib/sphero/request.rb", "lib/sphero/response.rb", "test/test_sphero.rb", "test/test_sphero_request.rb"]
  s.homepage = "http://github.com/hybridgroup/sphero"
  s.rdoc_options = ["--main", "README.markdown"]
  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.2")
  s.rubyforge_project = "sphero"
  s.rubygems_version = "1.8.24"
  s.summary = "A ruby gem for controlling your Sphero ball"
  s.test_files = ["test/test_sphero.rb", "test/test_sphero_request.rb"]

  s.add_runtime_dependency('rubyserial', '0.1.0')

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rdoc>, ["~> 4.0"])
      s.add_development_dependency(%q<hoe>, ["~> 3.6"])
    else
      s.add_dependency(%q<rdoc>, ["~> 4.0"])
      s.add_dependency(%q<hoe>, ["~> 3.6"])
    end
  else
    s.add_dependency(%q<rdoc>, ["~> 4.0"])
    s.add_dependency(%q<hoe>, ["~> 3.6"])
  end
end
