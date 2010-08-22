module Tanuki

  # Tanuki::Configurator is a scope for evaluating a Tanuki application configuration block.
  # Use Tanuki::development_application and Tanuki::production_application to create such a block.
  class Configurator

    # Creates a new configurator.
    def initialize(ctx)
      @context = ctx
      set :root, File.expand_path('..', $0)
      @config_root = File.join(@context.root, 'config');
    end

    # Loads and executes a given configuraion file with symbolic name +config+.
    def load_config(config)
      instance_eval File.read(File.join(@config_root, config.to_s) << '.rb')
    end

    private

    # Invokes Tanuki::Argument::store.
    def argument(klass, arg_class)
      Argument.store(klass, arg_class)
    end

    # Sets an +option+ to +value+ in the current context.
    def set(option, value)
      @context.send("#{option}=".to_sym, value)
    end

    # Invokes Tanuki::Application::use.
    def use(middleware, *args, &block)
      Application.use(middleware, *args, &block)
    end

    # Invokes Tanuki::Application::discard.
    def discard(middleware)
      Application.discard(middleware)
    end

    # Invokes Tanuki::Application::visitor.
    def visitor(sym, &block)
      Application.visitor(sym, &block)
    end

  end # end Configurator

end # end Tanuki