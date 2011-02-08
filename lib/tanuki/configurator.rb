module Tanuki

  # Tanuki::Configurator is a scope for evaluating
  # a Tanuki application configuration block.
  class Configurator

    # Configuration root.
    attr_writer :config_root

    # Creates a new configurator in context +ctx+ and +root+ directory.
    # Configuration root +config_root+ defaults
    # to _config_ directory in +root+.
    def initialize(ctx, root, config_root=nil)
      @context = ctx
      set :root, root ? root : Dir.pwd
    end

    # Loads and executes a given configuraion file
    # with symbolic name +config+.
    # If +silent+ is +true+, exception is not raised on missing file.
    def load_config(config, silent=false)
      file = File.join(@config_root, config.to_s) << '.rb'
      return if silent && !(File.file? file)
      instance_eval File.read(file)
      true
    end

    private

    # Invokes Tanuki::Argument::store.
    def argument(klass, arg_class)
      Argument.store klass, arg_class
    end

    # Sets an +option+ to +value+ in the current context.
    def set(option, value)
      @context.send "#{option}=".to_sym, value
    end

    # Invokes Tanuki::Application::use.
    def use(middleware, *args, &block)
      Application.use middleware, *args, &block
    end

    # Invokes Tanuki::Application::discard.
    def discard(middleware)
      Application.discard middleware
    end

    # Invokes Tanuki::Application::visitor.
    def visitor(sym, &block)
      Application.visitor sym, &block
    end

  end # Configurator

end # Tanuki
