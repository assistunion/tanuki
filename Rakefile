require File.join(File.expand_path('..', __FILE__), 'lib', 'tanuki', 'version.rb')

task :build do
  system 'gem build tanuki.gemspec'
end

task :release => :build do
  system "gem push tanuki-#{::Tanuki::VERSION}"
end