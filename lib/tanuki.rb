libdir = File.dirname(__FILE__)
$:.unshift(libdir) unless $:.include?(libdir)

require 'rack'
require 'fileutils'
require 'yaml'
require 'tanuki/application'
require 'tanuki/localization'
require 'tanuki/template_compiler'

module Tanuki
  VERSION = 'alpha'
end

def application(&block)
  def Object.const_missing(sym)
    if File.file?(path = Tanuki::Application.class_path(sym))
      require path
      const_get(sym)
    else
      super
    end
  end
  app = Tanuki::Application.defaults
  app.instance_eval(&block) if block_given?
  app.run
end