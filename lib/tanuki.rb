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
require 'tanuki/behavior/controller_behavior'
require 'tanuki/behavior/meta_model_behavior'
require 'tanuki/behavior/model_behavior'
require 'tanuki/behavior/object_behavior'
require 'tanuki/argument'
require 'tanuki/configurator'
require 'tanuki/context'
require 'tanuki/launcher'
require 'tanuki/loader'
require 'tanuki/i18n'
require 'tanuki/template_compiler'
require 'tanuki/application'

module Tanuki

  class << self

    # Runs application in a given environment +env+.
    def run(env)
      @cfg = Configurator.new(Context, nil, File.expand_path(File.join('..', '..', 'config'), __FILE__))
      @cfg.load_config(([:development, :production].include? env) ? :"#{env}_application" : :common_application)
      @cfg.config_root = File.expand_path(File.join('..', 'config'), $0)
      @cfg.load_config :"#{env}_application", true
      Application.run
    end

  end # end class << self

end