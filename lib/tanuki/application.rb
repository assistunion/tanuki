module Tanuki

  # Tanuki::Application is the starting point for all framework applications.
  # It contains core application functionality like configuration, request handling and view management.
  class Application

    @context = Context.new
    @rack_middleware = {}

    class << self

      # Returns the path to a source file containing class klass.
      def class_path(klass)
        path = const_to_path(klass, @context.app_root, File::SEPARATOR)
        File.join(path, path.match("#{File::SEPARATOR}([^#{File::SEPARATOR}]*)$")[1] << '.rb')
      end

      # Removes a given middleware from the Rack middleware pipeline
      def discard(middleware)
        @rack_middleware.delete(middleware)
      end

      # Checks if templates contain a compiled template sym for class klass
      def has_template?(templates, klass, sym)
        templates.include? "#{klass}##{sym}"
      end

      # Runs the application with current settings
      def run
        rack_builder = Rack::Builder.new
        @rack_middleware.each {|middleware, params| rack_builder.use(middleware, *params[0], &params[1]) }
        rack_builder.run(rack_app)
        srv = available_server
        puts "A wild Tanuki appears!", "You used #{srv.name.gsub(/.*::/, '')} at #{@context.host}:#{@context.port}."
        srv.run rack_builder.to_app, :Host => @context.host, :Port => @context.port
      end

      # Runs template sym from obj.
      # Template is recompiled from source on two conditions:
      # * template source modification time is older than compiled template modification time,
      # * Tanuki::TemplateCompiler source modification time is older than compiled template modification time.
      def run_template(templates, obj, sym, *args, &block)
        st_path = source_template_path(obj.class, sym)
        if st_path
          owner = template_owner(obj.class, sym)
          ct_path = compiled_template_path(obj.class, sym)
          ct_file_exists = File.file?(ct_path)
          ct_file_mtime = ct_file_exists ? File.mtime(ct_path) : nil
          st_file = File.new(st_path, 'r:UTF-8')
          if !ct_file_exists || st_file.mtime > ct_file_mtime ||
              File.mtime(File.join(CLASSES_DIR, 'template_compiler.rb')) > ct_file_mtime
            no_refresh = compile_template(st_file, ct_path, ct_file_mtime, owner, sym)
          else
            no_refresh = false
          end
          method_name = "#{sym}_view".to_sym
          owner.instance_eval do
            unless (method_exists = instance_methods(false).include? method_name) && no_refresh
              remove_method method_name if method_exists
              load ct_path
            end
          end
          templates["#{owner}##{sym}"] = nil
          templates["#{obj.class}##{sym}"] = nil
          obj.send(method_name, *args, &block)
        else
          raise "undefined template `#{sym}' for #{obj.class}"
        end
      end

      # Sets an option to value in the current context.
      def set(option, value)
        @context.send("#{option}=".to_sym, value)
      end

      # Adds a given middleware to the Rack middleware pipeline
      def use(middleware, *args, &block)
        @rack_middleware[middleware] = [args, block]
      end

      # Adds a template visitor block. This block must return a Proc.
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
        Tanuki_Object.instance_eval { define_method "#{sym}_visitor".to_sym, &block }
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

      # Returns an array of template outputs for controller ctrl in context ctx.
      def build_body(ctrl, request_ctx)
        Launcher.new(ctrl, request_ctx).each &Tanuki_Object.new.array_visitor
      end

      # Compiles template sym from owner class using source in st_file to ct_path.
      # Compilation is only done if destination file modification time has not changed
      # (is equal to ct_file_mtime) since file locking was initiated.
      def compile_template(st_file, ct_path, ct_file_mtime, owner, sym)
        no_refresh = true
        st_file.flock(File::LOCK_EX)
        if !File.file?(ct_path) || File.mtime(ct_path) == ct_file_mtime
          no_refresh = false
          ct_dir = File.dirname(ct_path)
          FileUtils.mkdir_p(ct_dir) unless File.directory?(ct_dir)
          File.open(tmp_ct_path = ct_path + '~', 'w:UTF-8') do |ct_file|
            TemplateCompiler.compile_template(ct_file, st_file.read, owner, sym)
          end
          FileUtils.mv(tmp_ct_path, ct_path)
        end
        st_file.flock(File::LOCK_UN)
        no_refresh
      end

      # Returns the path to a compiled template file containing template method_name for class klass.
      def compiled_template_path(klass, method_name)
        template_path(klass, method_name, @context.cache_root, '.', '.rb')
      end

      # Transforms a given constant klass to path with a given root and separated by sep.
      def const_to_path(klass, root, sep)
        File.join(root, klass.to_s.split('_').map {|item| item.gsub(/(?!^)([A-Z])/, '_\1') }.join(sep)).downcase
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
            match[1] << "?#{env['QUERY_STRING']}" unless env['QUERY_STRING'].empty?
            [301, {'Location' => match[1], 'Content-Type' => 'text/html; charset=utf-8'}, []]
          else
            request_ctx.env = env
            ctrl = Tanuki_Controller.dispatch(request_ctx, ctx.i18n ? Tanuki_I18n : ctx.root_page,
              Rack::Utils.unescape(env['REQUEST_PATH']).force_encoding('UTF-8'))
            case ctrl.result_type
            when :redirect then
              [302, {'Location' => ctrl.result, 'Content-Type' => 'text/html; charset=utf-8'}, []]
            when :page then
              [200, {'Content-Type' => 'text/html; charset=utf-8'}, build_body(ctrl, request_ctx)]
            else
              [404, {'Content-Type' => 'text/html; charset=utf-8'}, build_body(ctrl, request_ctx)]
            end
          end
        end
      end

      # Returns the path to a source file containing template method_name for class klass.
      def source_template_path(klass, method_name)
        template_path(klass, method_name, @context.app_root, File::SEPARATOR, '.erb')
      end

      # Finds the direct template method_name owner among ancestors of class klass.
      def template_owner(klass, method_name)
        method_file = method_name.to_s << '.erb'
        klass.ancestors.each do |ancestor|
          return ancestor if File.file? File.join(const_to_path(ancestor, @context.app_root, File::SEPARATOR), method_file)
        end
        nil
      end

      # Returns the path to a file containing template method_name for class klass with a given root, extension ext, and separated by sep.
      def template_path(klass, method_name, root, sep, ext)
        if owner = template_owner(klass, method_name)
          return File.join(const_to_path(owner, root, sep), method_name.to_s << ext)
        end
        nil
      end

    end # end class << self

  end # end Application

end # end Tanuki
