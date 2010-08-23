libdir = File.dirname(__FILE__)
$:.unshift(libdir) unless $:.include?(libdir)

require 'rack'
require 'fileutils'
require 'sequel'
require 'yaml'
require 'escape_utils'
require File.join('escape_utils', 'url', 'rack')
require File.join('tanuki', 'version')
require File.join('tanuki', 'extensions', 'module_extensions')
require File.join('tanuki', 'extensions', 'object_extensions')
require File.join('tanuki', 'argument')
require File.join('tanuki', 'configurator')
require File.join('tanuki', 'context')
require File.join('tanuki', 'controller_behavior')
require File.join('tanuki', 'launcher')
require File.join('tanuki', 'loader')
require File.join('tanuki', 'i18n')
require File.join('tanuki', 'object_behavior')
require File.join('tanuki', 'template_compiler')
require File.join('tanuki', 'application')

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