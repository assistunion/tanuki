require 'etc'
require File.expand_path('../lib/tanuki/version', __FILE__)
Gem::Specification.new do |s|
  s.name = 'tanuki'
  s.version = ::Tanuki::VERSION
  s.summary = 'Web framework with balls!'
  s.description = 'Tanuki is an MVVM-inspired web framework that fancies idiomatic Ruby, DRY and extensibility by its design.'

  s.required_ruby_version = '~> 1.9.2'
  s.required_rubygems_version = '>= 1.3.6'

  s.authors = ['Anatoly Ressin', 'Dimitry Solovyov']
  s.email = 'tanuki@withballs.org'
  s.homepage = 'http://withballs.org'

  s.files = Dir.glob(File.join("{#{File.join('app', '{tanuki,user}')},bin,config,lib,#{File.join('schema', 'tanuki')}}",
    '**', '*')) << 'LICENSE' << 'README.rdoc'
  s.executables = %w{tanuki}

  s.add_runtime_dependency 'rack', '~> 1.0'
  s.add_runtime_dependency 'sequel', '~> 3.14'
  s.add_runtime_dependency 'escape_utils', '~> 0.1'
  s.add_runtime_dependency 'activesupport', '~> 3.0'
  s.add_runtime_dependency 'i18n', '~> 0.4'
  s.add_development_dependency 'rspec', '~> 1.3'
end
