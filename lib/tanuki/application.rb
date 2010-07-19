module Tanuki
  class Application
    @templates = {}

    def self.has_template?(klass, sym)
      @templates.include? "#{klass}##{sym}"
    end

    def self.run_template(obj, sym, *args, &block)
      st_path = source_template_path(obj.class, sym)
      if st_path
        owner = template_owner(obj.class, sym)
        ct_path = compiled_template_path(obj.class, sym)
        if !File.file?(ct_path) ||
            File.mtime(st_path) > File.mtime(ct_path) ||
            File.mtime(File.join(CLASSES_DIR, 'template_compiler.rb')) >
            File.mtime(ct_path)
          ct_dir = File.dirname(ct_path)
          FileUtils.mkdir_p(ct_dir) unless File.directory?(ct_dir)
          File.open(ct_path, 'w') do |file|
            TemplateCompiler.compile(file, File.read(st_path), owner, sym)
          end
        end
        unless has_template?(owner, sym)
          require ct_path
          @templates["#{owner}##{sym}"] = nil
        end
        @templates["#{obj.class}##{sym}"] = nil
        obj.send("#{sym}_view".to_sym, *args, &block)
      else
        raise "undefined template `#{sym}' for #{klass}"
      end
    end

    def self.set(option, value)
      (class << self; self; end).instance_eval do
        undef_method option if method_defined? option
        if value.is_a? Proc
          define_method(option, &value)
        else
          define_method(option) { value }
        end
      end
      self
    end

    def self.visitor(sym, &block)
      Tanuki_Object.instance_eval { define_method sym, &block }
    end

    def self.defaults
      set :server, [:thin, :mongrel, :webrick]
      set :host, 'localhost'
      set :port, 3000
      set :root, '.'
      set :app_root, proc { File.join(root, 'app') }
      set :cache_root, proc { File.join(root, 'cache') }
      self
    end

    def self.run
      root_page = User_Page_Language
      rack_app = Rack::Builder.new do
        rack_proc = proc do |env|
          puts '%15s %s %s' % [
            env['REMOTE_ADDR'],
            env['REQUEST_METHOD'],
            env['REQUEST_URI']
          ]
          ctrl = Tanuki_Controller.dispatch(env, root_page, env['REQUEST_PATH'])
          case ctrl.result_type
          when :redirect then
            [302, {'Location' => ctrl.result}, []]
          when :page_missing then
            [404, {'Content-Type' => 'text/html; charset=utf-8'}, Tanuki::Launcher.new(ctrl)]
          else
            [200, {'Content-Type' => 'text/html; charset=utf-8'}, Tanuki::Launcher.new(ctrl)]
          end
        end
        run rack_proc
      end.to_app
      srv = available_server
      puts "A wild Tanuki appears!"
      puts "You used #{srv.name.gsub(/.*::/, '')} at #{host}:#{port}."
      srv.run rack_app, :Host => host, :Port => port
    end

    def self.class_path(klass)
      path = const_to_path(klass, Application.app_root, File::SEPARATOR)
      File.join(path, path.match(
        "#{File::SEPARATOR}([^#{File::SEPARATOR}]*)$")[1] << '.rb')
    end

    class << self
      private

      def available_server
        server.each do |server_name|
          begin
            return Rack::Handler.get(server_name.downcase)
          rescue LoadError
          rescue NameError
          end
        end
        raise "servers #{server.join(', ')} not found"
      end

      def const_to_path(klass, root, sep)
        File.join(root, klass.to_s.split('_').map do |item|
          item.gsub(/(?!^)([A-Z])/, '_\1')
        end.join(sep)).downcase
      end

      def template_owner(klass, method_name)
        klass.ancestors.each do |ancestor|
          return ancestor if File.file? File.join(
            const_to_path(ancestor, Application.app_root, File::SEPARATOR),
            method_name.to_s << '.erb')
        end
        nil
      end

      def template_path(klass, method_name, root, sep, ext)
        if owner = template_owner(klass, method_name)
          return File.join(const_to_path(owner, root, sep),
            method_name.to_s << ext)
        end
        nil
      end

      def source_template_path(klass, method_name)
        template_path(klass, method_name, Application.app_root,
          File::SEPARATOR, '.erb')
      end

      def compiled_template_path(klass, method_name)
        template_path(klass, method_name, Application.cache_root, '.', '.rb')
      end
    end
  end
end