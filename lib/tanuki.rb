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
require 'tanuki/controller_behavior'
require 'tanuki/launcher'
require 'tanuki/loader'
require 'tanuki/i18n'
require 'tanuki/object_behavior'
require 'tanuki/template_compiler'
require 'tanuki/application'