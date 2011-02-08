Gem::Specification.new do |s|
  s.name = %q{chit}
  s.version = "1.0"

  s.specification_version = 2 if s.respond_to? :specification_version=

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Robin Lu"]
  s.date = %q{2008-06-19}
  s.default_executable = %q{chit}
  s.description = %q{Chit is A command line tool for cheat sheet utility based on git.}
  s.email = ["iamawalrus@gmail.com"]
  s.executables = ["chit"]
  s.extra_rdoc_files = ["Manifest.txt", "README.rdoc"]
  s.files = ["Manifest.txt", "README.txt", "Rakefile", "bin/chit", "lib/chit.rb", "lib/wrap.rb", "resources/chitrc", "test/test_chit.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/robin/chit}
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{chit}
  s.rubygems_version = %q{1.0.1}
  s.summary = %q{Chit is A command line tool for cheat sheet utility based on git.}
  s.test_files = ["test/test_chit.rb"]

  s.add_dependency(%q<schacon-git>, [">= 1.0"])
  s.add_dependency(%q<hoe>, [">= 1.5.3"])
end