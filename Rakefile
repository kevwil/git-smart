require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  warn e.message
  warn 'Run `bundle install` to install missing gems'
  exit e.status_code
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

desc 'Generate a binary for each of our commands'
task :generate_binaries do
  base_dir = __dir__
  require "#{base_dir}/lib/git-smart"

  require 'fileutils'
  FileUtils.mkdir_p "#{base_dir}/bin"
  GitSmart.commands.each_key { |cmd|
    filename = "#{base_dir}/bin/git-#{cmd}"
    File.open(filename, 'w') { |out|
      out.puts %Q{#!/usr/bin/env ruby

$LOAD_PATH.unshift(File.join(File.expand_path(__dir__), '..', 'lib'))

require 'git-smart'

GitSmart.run('#{cmd}', ARGV)
}
    }
    `chmod a+x #{filename}`
    `cd #{base_dir} && git add #{filename}`
    puts "Wrote #{filename}"
  }
end

task build: :generate_binaries

task default: :spec
