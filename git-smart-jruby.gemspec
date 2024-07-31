Gem::Specification.new do |s|
  s.name = %q{git-smart-jruby}
  s.version = "0.2.0"

  s.authors = ["Glen Maddern", "Kevin Williams"]
  s.email = %q{glenmaddern@gmail.com}
  s.date = %q{2024-07-25}
  s.summary = %q{Add some smarts to your git workflow}
  s.description = %q{Installs some additional 'smart' git commands, like `git smart-pull`.}
  s.homepage = %q{https://github.com/geelen/git-smart}
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]

  s.extra_rdoc_files = %w[LICENSE.txt README.md]

  s.executables = `git ls-files -- bin`.split("\n").map{|f| File.basename(f) }
  s.files       = `git ls-files -- {lib,docs}`.split("\n") + %w[Gemfile Gemfile.lock LICENSE.txt README.md Rakefile VERSION]
  s.test_files  = `git ls-files -- spec`.split("\n")

  s.add_runtime_dependency "colorize", "~> 1.1", ">= 1.1.0"
  s.add_runtime_dependency "spoon", "~> 0.0", ">= 0.0.6"

  s.add_development_dependency "rspec", "~> 3.13", ">= 3.13.0"
  s.add_development_dependency "simplecov", "~> 0.22", ">= 0.22.0"
  # s.add_development_dependency "rocco", "~> 0.8", ">= 0.8.2"

  s.required_ruby_version = '>= 2.7.0'
end
