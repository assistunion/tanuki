require 'rake/rdoctask'
require 'rspec/core/rake_task'
libdir = File.join(File.expand_path('..', __FILE__), 'lib')
require File.join(libdir, 'tanuki/version')

RSpec::Core::RakeTask.new do |t|
  t.pattern = 'spec/**/*_spec.rb'
  t.rspec_opts = ['--format', 'documentation']
end

Rake::RDocTask.new do |rd|
  rd.main = 'README.rdoc'
  rd.options << '--all'
  rd.rdoc_dir = 'docs'
  rd.rdoc_files.include 'README.rdoc', 'LICENSE', File.join('lib', '**', '*.rb')
  rd.title = 'Tanuki Documentation'
end

desc 'Build gem from current sources'
task :build do
  system 'gem build tanuki.gemspec'
end

desc 'Build gem from current sources and push to RubyGems.org'
task :release => :build do
  system "gem push tanuki-#{::Tanuki.version}.gem"
end

desc 'Run specs, build RDoc, and build gem'
task :all => [:spec, :rdoc, :build]

task :default => :all
