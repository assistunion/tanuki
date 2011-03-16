libdir = File.dirname(__FILE__)
$:.unshift(libdir) unless $:.include?(libdir)

require 'fileutils'
require 'stringio'
require 'yaml'

require 'active_support/all'
require 'escape_utils'
require 'escape_utils/url/rack'
require 'rack'
require 'sequel'

require 'tanuki/version'
require 'tanuki/const'
require 'tanuki/extensions/module'
require 'tanuki/extensions/rack/frozen_route'
require 'tanuki/extensions/rack/static_dir'
require 'tanuki/base_behavior'
require 'tanuki/extensions/sequel/model'
require 'tanuki/argument'
require 'tanuki/configurator'
require 'tanuki/context'
require 'tanuki/controller'
require 'tanuki/css_compressor'
require 'tanuki/loader'
require 'tanuki/meta_model'
require 'tanuki/model_behavior'
require 'tanuki/i18n'
require 'tanuki/template_compiler'
require 'tanuki/application'

module Tanuki
end
