module Tanuki
  libdir = File.dirname(__FILE__)
  $:.unshift(libdir) unless $:.include?(libdir)
  CLASSES_DIR = File.join(libdir, 'tanuki')
  VERSION = 'alpha'
end

require 'rack'
require 'fileutils'
require 'yaml'
require 'escape_utils'
require 'escape_utils/url/rack'
require 'tanuki/configurator'
require 'tanuki/context'
require 'tanuki/launcher'
require 'tanuki/template_compiler'
require 'tanuki/application'

def Object.const_missing(sym)
  if File.file?(path = Tanuki::Application.class_path(sym))
    require path
    return const_get(sym)
  end
  super
end