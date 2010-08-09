module Tanuki

  # Tanuki::Configurator is a scope for evaluating a Tanuki application configuration block.
  # Use Tanuki::development_application and Tanuki::production_application to create such a block.
  class Configurator

    class << self

      private

      # Invokes Tanuki::Application::set.
      def set(option, value)
        Application.set(option, value)
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

    end # end class << self

  end # end Configurator

  # Creates default configuration for development environments.
  def self.development_application(&block)
    Application.instance_eval do
      use Rack::CommonLogger
      use Rack::Lint
      use Rack::Reloader, 0
      use Rack::ShowExceptions
    end
    common_application(&block)
  end

  # Creates default configuration for production environments.
  def self.production_application(&block)
    common_application(&block)
  end

  private

  # Creates default configuration for common environments.
  def self.common_application(&block)
    Application.instance_eval do
      use Rack::Head
      use Rack::ShowStatus
      set :server, [:thin, :mongrel, :webrick]
      set :host, '0.0.0.0'
      set :port, 3000
      set :root, File.dirname($0)
      set :app_root, proc { File.join(root, 'app') }
      set :cache_root, proc { File.join(root, 'cache') }
      set :root_page, ::User_Page_Index
      set :missing_page, ::Tanuki_Missing
      set :i18n, false
      set :language, nil
      set :language_fallback, {}
      set :languages, proc { language_fallback.keys }
      set :best_language, proc {|lngs| language_fallback[language].each {|lng| return lng if lngs.include? lng }; nil }
      set :best_translation, proc {|trn| language_fallback[language].each {|lng| return trn[lng] if trn.include? lng }; nil }
      visitor :string do s = ''; proc {|out| s << out.to_s } end
    end
    Application.instance_eval { @context = @context.child }
    Configurator.instance_eval(&block) if block_given?
    Application.run
  end

end # end Tanuki