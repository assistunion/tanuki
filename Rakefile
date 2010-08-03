require 'rake/rdoctask'
require File.join('lib', 'tanuki', 'version.rb')

desc 'Build gem from current sources'
task :build do
  system 'gem build tanuki.gemspec'
end

desc 'Build gem from current sources and push to RubyGems.org'
task :release => :build do
  system "gem push tanuki-#{::Tanuki::VERSION}"
end

Rake::RDocTask.new do |rd|
  rd.main = 'README.rdoc'
  rd.options << '--all'
  rd.rdoc_dir = 'docs'
  rd.rdoc_files.include 'README.rdoc', 'LICENSE', File.join('lib', '**', '*.rb')
  rd.title = 'Tanuki Documentation'
end