require 'etc'
require File.join(File.expand_path('..', __FILE__), 'lib', 'tanuki', 'version.rb')
Gem::Specification.new do |s|
  s.name = 'tanuki'
  s.version = ::Tanuki::VERSION
  s.summary = 'Web framework with balls!'
  s.description = 'Tanuki is an MVVM-inspired web framework that fancies idiomatic Ruby, DRY and extensibility by its design.'

  s.required_ruby_version = '>= 1.9.1'
  s.required_rubygems_version = '>= 1.3.6'

  s.authors = ['Anatoly Ressin', 'Dimitry Solovyov']
  s.email = 'tanuki@dimituri.com'
  s.homepage = 'http://bitbucket.org/dimituri/tanuki'

  s.files = Dir.glob(File.join("{#{File.join('app', 'tanuki')},bin,lib,#{File.join('schema', 'tanuki')}}", '**', '*')).select {|v| File.file? v } << 'LICENSE' << 'README.rdoc'
  s.executables = %w{tanuki}

  s.add_runtime_dependency 'rack', '>= 1.0'
  s.add_runtime_dependency 'escape_utils', '>= 0.1.5'
  s.add_development_dependency 'rake', '>= 0.8.7'

  s.post_install_message = "#{'=' * 79}\n\nHello #{Etc.getlogin}!\nYour very own Tanuki adventure awaits!\n" \
    "Type `tanuki init yourproject' to get started.\nTyping `tanuki help' will show what you can do.\n\n#{'=' * 79}"
end