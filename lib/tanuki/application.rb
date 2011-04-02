module Tanuki

  # Tanuki::Application is the starting point for all framework applications.
  # It contains core application functionality like configuration, request
  # handling and view management.
  class Application

    Loader.context = Context
    @rack_middleware = []

    class << self

      # Initializes the application in a given Rack::Builder +builder+.
      def build(builder)
        puts %{Calling for Tanuki #{Tanuki.version} in "#{Dir.pwd}"}
        configure
        if @cfg.context.development
          Loader.prepare_for_development
        else
          Loader.prepare_for_production
        end
        at_exit { puts 'Tanuki ran away!' }
        configure_middleware(builder)
        vowel = @environment =~ /\A[aeiou]/
        puts "A#{'n' if vowel} #{@environment} Tanuki appears!"
        rack_app
      end

      # Removes all occurences of a given +middleware+ from the Rack
      # middleware pipeline.
      def discard(middleware)
        @rack_middleware.delete_if {|item| item[0] == middleware }
      end

      # Returns current environment +Symbol+, if application is configured.
      # Returns +nil+ otherwise.
      def environment
        @environment ||= nil
      end

      # Pulls all occurences of a given +middleware+ down to the end
      # of the Rack middleware pipeline (it would have the lowest priority).
      def pull_down(middleware)
        items = @rack_middleware.select {|item| item[0] == middleware }
        if items
          @rack_middleware.reject! {|item| item[0] == middleware }
          items.each {|item| @rack_middleware << item }
        end
      end

      # Adds a given +middleware+ with optional +args+ and +block+
      # to the Rack middleware pipeline.
      def use(middleware, *args, &block)
        @rack_middleware << [middleware, args, block]
      end

      # Adds a template visitor +block+. This +block+ must return a +Proc+.
      #
      #  visitor :escape do
      #    s = ''
      #    proc {|out| s << CGI.escapeHTML(out.to_s) }
      #  end
      #  visitor :printf do |format|
      #    s = ''
      #    proc {|out| s << format % out.to_s }
      #  end
      #
      # It can later be used in a template via the visitor syntax.
      #
      #  <%_escape escaped_view %>
      #  <%_printf('<div>%s</div>') formatted_view %>
      def visitor(sym, &block)
        BaseBehavior.instance_eval do
          define_method "#{sym}_visitor".to_sym, &block
        end
      end

      private

      # Initializes application settings using configuration
      # for the current Rack environment.
      # These include settings for server, context, and middleware.
      def configure
        @environment = ENV['RACK_ENV'].to_sym
        default_root = File.expand_path('../../..', __FILE__)
        @cfg = Configurator.new(Context, pwd = Dir.pwd)
        env_config = :"#{@environment}_application"

        # Configure in default root (e.g. gem root)
        if pwd != default_root
          @cfg.config_root = File.join(default_root, 'config')
          if [:development, :production].include? @environment
            default_config = env_config
          else
            default_config = :common_application
          end
          @cfg.load_config default_config
        end

        # Configure in application root
        @cfg.config_root = File.join(pwd, 'config')
        if @cfg.config_file? env_config
          @cfg.load_config env_config, pwd != default_root
        elsif @cfg.config_file? :common_application
          @cfg.load_config :common_application
        end

        # Configure root page children
        DEFAULT_PAGE_OPTIONS[:controller] = @cfg.context.default_page
        DEFAULT_PAGE_OPTIONS[:controller].freeze
        tree = YAML.load_file(File.join(@cfg.config_root, 'webpages.yml'))
        merge_tree_config_with_defaults(tree)
        @cfg.context.autoconfiguration = tree

        self
      rescue NameError => e
        raise e unless e.name =~ /\AA-Z/
        message = "missing class or module for constant `#{e.name}'"
        raise NameError, message, e.backtrace
      end

      DEFAULT_PAGE_OPTIONS = {
        :title => 'Untitled',
        :autoselect_first => false,
        :hidden => false,
        :children => {}
      }

      def merge_tree_config_with_defaults(children)
        children.symbolize_keys!

        children.each_value do |tree|
          tree.symbolize_keys!
          if tree.key? :controller
            tree[:controller] = tree[:controller].constantize
          end
          tree = DEFAULT_PAGE_OPTIONS.merge(tree)
          merge_tree_config_with_defaults tree[:children]
        end

      end

      # Add utilized middleware to a given Rack::Builder instance
      # +rack_builder+.
      def configure_middleware(rack_builder)
        @rack_middleware.each do |item|
          rack_builder.use item[0], *item[1], &item[2]
        end
      end

      # Returns a Rack app block for Rack::Builder.
      # This block is passed a request environment
      # and returns and array of three elements:
      # * a response status code,
      # * a hash of headers,
      # * an iterable body object.
      # It is run on each request.
      def rack_app
        proc do |env|

          # If there are trailing slashes in path, don't dispatch
          path_info = env[Const::PATH_INFO]
          if match = path_info.match(Const::TRAILING_SLASH)

            # Remove trailing slash in the path and redirect
            loc = match[1]
            query_string = env[Const::QUERY_STRING]
            loc << "?#{query_string}" unless query_string.empty?
            [
              301,
              {
                Const::LOCATION     => loc,
                Const::CONTENT_TYPE => Const::MIME_TEXT_HTML
              },
              Const::EMPTY_ARRAY
            ]

          else
            ctx = Context.child
            ctx.templates = {}
            ctx.resources = {}
            ctx.javascripts = {}

            # Dispatch controller chain for the current path
            Loader.refresh_css if ctx.development
            ctx.request = Rack::Request.new(env)
            resp = ctx.response = Rack::Response.new(
              [],
              200,
              {Const::CONTENT_TYPE => Const::MIME_TEXT_HTML}
            )
            template = nil
            catch :halt do
              template = ::Tanuki::Controller.dispatch(
                ctx,
                Context.i18n ? ::Tanuki::I18n : ctx.autoconfiguration[:root][:controller],
                Rack::Utils.unescape(path_info).force_encoding(Const::UTF_8)
              )
            end
            if template &&
               template.is_a?(Method) &&
               template.receiver.is_a?(BaseBehavior) &&
               template.name =~ Const::VIEW_METHOD
            then
              resp.finish do |resp|
                template.call.call(proc {|s| resp.write s }, ctx)
              end
            else
              resp.finish
            end

          end # if

        end # proc
      end # rack_app

    end # class << self

  end # Application

end # Tanuki
