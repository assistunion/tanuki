module Tanuki

  module Utility

    @help[:generate] = 'generate models for application schema'

    # Generates models for application schema
    # in the current directory or +cwd+.
    def self.generate(cwd=nil)
      version unless @in_repl
      cwd = cwd ? File.expand_path(cwd) : Dir.pwd
      puts "Working directory is: #{cwd}",
           "To specify another: `generate <path>'"
      require 'active_support/inflector'
      require 'yaml'
      require 'fileutils'
      require 'tanuki/behavior/meta_model_behavior'
      require 'tanuki/behavior/model_behavior'
      require 'tanuki/behavior/base_behavior'
      require 'tanuki/configurator'
      require 'tanuki/context'
      require 'tanuki/loader'
      require 'tanuki/template_compiler'
      require 'tanuki/model_generator'

      ctx = Loader.context = Context
      default_root = File.expand_path('../../../..', __FILE__)
      cfg = Configurator.new(ctx, cwd)

      # Load defaults
      cfg.config_root = File.join(default_root, 'config')
      cfg.load_config :common

      # Override with user settings if needed
      if cwd != default_root
        cfg.config_root = File.join(cwd, 'config')
        cfg.load_config :common, true
      end

      puts "\n looking for models"
      local_schema_root = File.expand_path('../../../../schema', __FILE__)
      mg = ModelGenerator.new(ctx)
      mg.generate ctx.schema_root
      unless ctx.schema_root == local_schema_root
        mg.generate local_schema_root
      end
      mg.tried.each_pair do |name, arys|
        puts "\n found: #{name}"
        arys.each_pair do |ary_name, ary|
          puts %{ #{ary_name}:\n - #{ary.join "\n - "}} unless ary.empty?
        end
      end
    end

  end # Utility

end # Tanuki
