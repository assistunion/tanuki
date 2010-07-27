module Tanuki
  class Configurator
    def self.set(option, value)
      Application.set(option, value)
    end

    def self.use(middleware, *args, &block)
      Application.use(middleware, *args, &block)
    end

    def self.visitor(sym, &block)
      Application.visitor(sym, &block)
    end
  end

  def self.development_application(&block)
    Application.instance_eval do
      use Rack::CommonLogger
      use Rack::Lint
      use Rack::ShowExceptions
    end
    common_application(&block)
  end

  def self.production_application(&block)
    common_application(&block)
  end

  private

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
      set :root_page, User_Page_Index
      set :i18n, false
      set :language, nil
      set :language_fallback, {}
      set :languages, proc { language_fallback.keys }
      set :best_language, proc {|lngs| language_fallback[language].each {|lng| return lng if lngs.include? lng }; nil }
      visitor :string do s = ''; proc {|out| s << out.to_s } end
      visitor :array do arr = []; proc {|out| arr << out.to_s } end
    end
    Application.instance_eval { @context = @context.child }
    Configurator.instance_eval(&block) if block_given?
    Application.run
  end
end