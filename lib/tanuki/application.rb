module Tanuki
  class Application
    @context = Context.new
    @rack_middleware = []

    def self.has_template?(templates, klass, sym)
      templates.include? "#{klass}##{sym}"
    end

    def self.run_template(templates, obj, sym, *args, &block)
      st_path = source_template_path(obj.class, sym)
      if st_path
        no_refresh = true
        owner = template_owner(obj.class, sym)
        ct_path = compiled_template_path(obj.class, sym)
        ct_file_exists = File.file?(ct_path)
        ct_file_mtime = ct_file_exists ? File.mtime(ct_path) : nil
        st_file = File.new(st_path, 'r:UTF-8')
        if !ct_file_exists || st_file.mtime > ct_file_mtime ||
            File.mtime(File.join(CLASSES_DIR, 'template_compiler.rb')) > ct_file_mtime
          st_file.flock(File::LOCK_EX)
          if !File.file?(ct_path) || File.mtime(ct_path) == ct_file_mtime
            no_refresh = false
            ct_dir = File.dirname(ct_path)
            FileUtils.mkdir_p(ct_dir) unless File.directory?(ct_dir)
            File.open(tmp_ct_path = ct_path + '~', 'w:UTF-8') do |ct_file|
              TemplateCompiler.compile(ct_file, st_file.read, owner, sym)
            end
            FileUtils.mv(tmp_ct_path, ct_path)
          end
          st_file.flock(File::LOCK_UN)
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

    def self.set(option, value)
      @context.send("#{option}=".to_sym, value)
    end

    def self.use(middleware, *args, &block)
      @rack_middleware << [middleware, args, block]
    end

    def self.visitor(sym, &block)
      Tanuki_Object.instance_eval { define_method "#{sym}_visitor".to_sym, &block }
    end

    def self.run
      ctx = @context
      rack_builder = Rack::Builder.new
      @rack_middleware.each {|middleware, args, block| rack_builder.use(middleware, *args, &block) }
      rack_app = proc do |env|
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

      def build_body(ctrl, request_ctx)
        Tanuki::Launcher.new(ctrl, request_ctx).each &Tanuki_Object.new.array_visitor
      end

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
