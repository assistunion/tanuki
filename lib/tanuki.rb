module Tanuki
  libdir = File.dirname(__FILE__)
  $:.unshift(libdir) unless $:.include?(libdir)
  CLASSES_DIR = File.join(libdir, 'tanuki')
  VERSION = 'alpha'
end

require 'rack'
require 'fileutils'
require 'yaml'
require 'tanuki/application'
require 'tanuki/launcher'
require 'tanuki/localization'
require 'tanuki/template_compiler'

def application(&block)
  def Object.const_missing(sym)
    if File.file?(path = Tanuki::Application.class_path(sym))
      require path
      return const_get(sym)
    end
    super
  end
  app = Tanuki::Application.defaults
  app.instance_eval(&block) if block_given?
  app.run
end