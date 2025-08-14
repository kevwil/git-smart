Gem::Specification.new do |s|
  s.name = 'git-smart'
  s.version = '0.2.1'

  s.authors = ['Glen Maddern', 'Kevin Williams']
  s.email = 'kevwil@gmail.com'
  s.date = '2025-07-10'
  s.summary = 'Add some smarts to your git workflow'
  s.description = "Installs some additional 'smart' git commands, like `git smart-pull`."
  s.homepage = 'https://github.com/kevwil/git-smart'
  s.licenses = ['MIT']
  s.require_paths = ['lib']

  s.extra_rdoc_files = %w[LICENSE.txt README.md]

  s.executables = `git ls-files -- bin`.split("\n").map { |f| File.basename(f) }
  s.files       = `git ls-files -- {lib,docs}`.split("\n") + %w[Gemfile Gemfile.lock LICENSE.txt README.md Rakefile VERSION]
  s.test_files  = `git ls-files -- spec`.split("\n")

  s.add_runtime_dependency 'colorize', '~> 1.1', '>= 1.1.0'

  s.add_development_dependency 'rspec', '~> 3.13', '>= 3.13.1'
  s.add_development_dependency 'drb', '~> 2.2', '>= 2.2.3'
  s.add_development_dependency 'ruby-debug-ide', '~> 0.7', '>= 0.7.5'
  s.add_development_dependency 'simplecov', '~> 0.22', '>= 0.22.0'
  s.add_development_dependency 'rubocop', '~> 1.79', '>= 1.79.2'

  s.required_ruby_version = '>= 2.7.0'
end
