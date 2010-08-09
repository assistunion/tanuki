module Tanuki
  libdir = File.dirname(__FILE__)
  $:.unshift(libdir) unless $:.include?(libdir)
end

require 'rack'
require 'fileutils'
require 'yaml'
require 'escape_utils'
require 'escape_utils/url/rack'
require 'tanuki/version'
require 'tanuki/module_extensions'
require 'tanuki/configurator'
require 'tanuki/context'
require 'tanuki/controller_base'
require 'tanuki/launcher'
require 'tanuki/loader'
require 'tanuki/object_base'
require 'tanuki/template_compiler'
require 'tanuki/application'