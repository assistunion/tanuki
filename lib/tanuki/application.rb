module Tanuki
  class Application
    @templates = {}
    @context = Tanuki::Context.new
    @rack_middleware = []

    def self.has_template?(klass, sym)
      @templates.include? "#{klass}##{sym}"
    end

    def self.run_template(obj, sym, *args, &block)
      st_path = source_template_path(obj.class, sym)
      if st_path
        owner = template_owner(obj.class, sym)
        ct_path = compiled_template_path(obj.class, sym)
        if !File.file?(ct_path) || File.mtime(st_path) > File.mtime(ct_path) ||
            File.mtime(File.join(CLASSES_DIR, 'template_compiler.rb')) > File.mtime(ct_path)
          ct_dir = File.dirname(ct_path)
          FileUtils.mkdir_p(ct_dir) unless File.directory?(ct_dir)
          File.open(ct_path, 'w') {|file| TemplateCompiler.compile(file, File.read(st_path), owner, sym) }
        end
        require ct_path
        @templates["#{owner}##{sym}"] = nil
        @templates["#{obj.class}##{sym}"] = nil
        obj.send("#{sym}_view".to_sym, *args, &block)
      else
        raise "undefined template `#{sym}' for #{obj.class}"
      end
    end

    def self.set(option, value)
      @context.send("#{option}=".to_sym, value)
    end

    def self.use(middleware, *args, &block)
      @rack_middleware << [middleware, args, block]
    end

    def self.visitor(sym, &block)
      Tanuki_Object.instance_eval { define_method sym, &block }
    end

    def self.configure(&block)
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
      @context = @context.child
      Tanuki::Configurator.instance_eval(&block) if block_given?
      self
    end

    def self.run
      ctx = @context
      rack_builder = Rack::Builder.new
      @rack_middleware.each {|middleware, args, block| rack_builder.use(middleware, *args, &block) }
      rack_app = proc do |env|
        request_ctx = ctx.child
        if match = env['REQUEST_PATH'].match(/^(.+)\/$/)
          match[1] << "?#{env['QUERY_STRING']}" unless env['QUERY_STRING'].empty?
          [301, {'Location' => match[1]}, []]
        else
          puts '%15s %s %s' % [env['REMOTE_ADDR'], env['REQUEST_METHOD'], env['REQUEST_URI']]
          request_ctx.env = env
          ctrl = Tanuki_Controller.dispatch(request_ctx, ctx.i18n ? Tanuki_I18n : ctx.root_page, env['REQUEST_PATH'])
          case ctrl.result_type
          when :redirect then
            [302, {'Location' => ctrl.result}, []]
          when :page then
            [200, {'Content-Type' => 'text/html; charset=utf-8'}, Tanuki::Launcher.new(ctrl, request_ctx)]
          else
            [404, {'Content-Type' => 'text/html; charset=utf-8'}, Tanuki::Launcher.new(ctrl, request_ctx)]
          end
        end
      end
      rack_builder.run(rack_app)
      srv = available_server
      puts "A wild Tanuki appears!", "You used #{srv.name.gsub(/.*::/, '')} at #{@context.host}:#{@context.port}."
      srv.run rack_builder.to_app, :Host => @context.host, :Port => @context.port
    end

    def self.class_path(klass)
      path = const_to_path(klass, @context.app_root, File::SEPARATOR)
      File.join(path, path.match("#{File::SEPARATOR}([^#{File::SEPARATOR}]*)$")[1] << '.rb')
    end

    class << self
      private

      def available_server
        @context.server.each do |server_name|
          begin
            return Rack::Handler.get(server_name.downcase)
          rescue LoadError
          rescue NameError
          end
        end
        raise "servers #{server.join(', ')} not found"
      end

      def const_to_path(klass, root, sep)
        File.join(root, klass.to_s.split('_').map {|item| item.gsub(/(?!^)([A-Z])/, '_\1') }.join(sep)).downcase
      end

      def template_owner(klass, method_name)
        method_file = method_name.to_s << '.erb'
        klass.ancestors.each do |ancestor|
          return ancestor if File.file? File.join(const_to_path(ancestor, @context.app_root, File::SEPARATOR), method_file)
        end
        nil
      end

      def template_path(klass, method_name, root, sep, ext)
        if owner = template_owner(klass, method_name)
          return File.join(const_to_path(owner, root, sep), method_name.to_s << ext)
        end
        nil
      end

      def source_template_path(klass, method_name)
        template_path(klass, method_name, @context.app_root,
          File::SEPARATOR, '.erb')
      end

      def compiled_template_path(klass, method_name)
        template_path(klass, method_name, @context.cache_root, '.', '.rb')
      end
    end
  end
end
