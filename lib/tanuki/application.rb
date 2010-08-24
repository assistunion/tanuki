module Tanuki

  # Tanuki::Application is the starting point for all framework applications.
  # It contains core application functionality like configuration, request handling and view management.
  class Application

    @context = (Loader.context = Context).child
    @rack_middleware = {}

    class << self

      # Removes a given middleware from the Rack middleware pipeline.
      def discard(middleware)
        @rack_middleware.delete(middleware)
      end

      # Runs the application with current settings.
      def run
        rack_builder = Rack::Builder.new
        @rack_middleware.each {|middleware, params| rack_builder.use(middleware, *params[0], &params[1]) }
        rack_builder.run(rack_app)
        srv = available_server
        puts "A wild Tanuki appears!", "You used #{srv.name.gsub(/.*::/, '')} at #{@context.host}:#{@context.port}."
        begin
          srv.run rack_builder.to_app, :Host => @context.host, :Port => @context.port
        rescue Interrupt
          puts 'Tanuki ran away!'
        end
      end

      # Adds a given +middleware+ with optional +args+ and +block+ to the Rack middleware pipeline.
      def use(middleware, *args, &block)
        @rack_middleware[middleware] = [args, block]
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
        ObjectBehavior.instance_eval { define_method "#{sym}_visitor".to_sym, &block }
      end

      private

      # Returns the first available server from a server list in the current context.
      def available_server
        @context.server.each do |server_name|
          begin
            return Rack::Handler.get(server_name.downcase)
          rescue LoadError
          rescue NameError
          end
        end
        raise "servers #{@context.server.join(', ')} not found"
      end

      # Returns an array of template outputs for controller +ctrl+ in context +request_ctx+.
      def build_body(ctrl, request_ctx)
        arr = []
        Launcher.new(ctrl, request_ctx).each &proc {|out| arr << out.to_s }
      end

      # Returns a Rack app block for Rack::Builder.
      # This block is passed a request environment and returns and array of three elements:
      # * a response status code,
      # * a hash of headers,
      # * an iterable body object.
      # It is run on each request.
      def rack_app
        ctx = @context
        proc do |env|
          request_ctx = ctx.child
          request_ctx.templates = {}
          if match = env['REQUEST_PATH'].match(/^(.+)(?<!\$)\/$/)
            loc = match[1]
            loc << "?#{env['QUERY_STRING']}" unless env['QUERY_STRING'].empty?
            [301, {'Location' => loc, 'Content-Type' => 'text/html; charset=utf-8'}, []]
          else
            request_ctx.env = env
            result = ::Tanuki::ControllerBehavior.dispatch(request_ctx, ctx.i18n ? ::Tanuki::I18n : ctx.root_page,
              Rack::Utils.unescape(env['REQUEST_PATH']).force_encoding('UTF-8'))
            case result[:type]
            when :redirect then
              [302, {'Location' => result[:location], 'Content-Type' => 'text/html; charset=utf-8'}, []]
            when :page then
              [200, {'Content-Type' => 'text/html; charset=utf-8'}, build_body(result[:controller], request_ctx)]
            else
              [404, {'Content-Type' => 'text/html; charset=utf-8'}, build_body(result[:controller], request_ctx)]
            end
          end
        end
      end

    end # end class << self

  end # end Application

end # end Tanuki
