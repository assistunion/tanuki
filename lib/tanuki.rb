libdir = File.dirname(__FILE__)
$:.unshift(libdir) unless $:.include?(libdir)

require 'rack'
require 'fileutils'
require 'sequel'
require 'yaml'
require 'escape_utils'
require 'escape_utils/url/rack'
require 'tanuki/version'
require 'tanuki/extensions/module_extensions'
require 'tanuki/extensions/object_extensions'
require 'tanuki/argument'
require 'tanuki/configurator'
require 'tanuki/context'
require 'tanuki/controller_behavior'
require 'tanuki/launcher'
require 'tanuki/loader'
require 'tanuki/i18n'
require 'tanuki/object_behavior'
require 'tanuki/template_compiler'
require 'tanuki/application'

module Tanuki

  class << self

    # Runs application in a given +environment+.
    def run(environment)
      @cfg = Configurator.new(Context)
      @cfg.load_config :common
      @cfg.load_config :"#{environment}_application"
      Application.run
    end

  end # end class << self

end