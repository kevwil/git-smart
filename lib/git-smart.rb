require 'rubygems'

class GitSmart
end

%w[core_ext git-smart commands].each do |dir|
  Dir.glob(File.join(__dir__, dir, '**', '*.rb')) { |f| require f }
end
