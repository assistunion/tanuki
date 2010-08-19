require 'rake/rdoctask'
require 'spec/rake/spectask'
require File.join('lib', 'tanuki', 'version.rb')

Spec::Rake::SpecTask.new do |t|
  t.libs = ['lib']
  t.pattern = 'spec/**/*_spec.rb'
  t.spec_opts = ['--format', 'specdoc']
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
  system "gem push tanuki-#{::Tanuki::VERSION}.gem"
end

desc 'Run specs, build RDoc, and build gem'
task :all => [:spec, :rdoc, :build]

task :default => :all