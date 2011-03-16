module Tanuki

  # Tanuki::Loader deals with framework paths resolving,
  # and object and template loading.
  class Loader

    class << self

      # Returns the path to a source file in +root+ containing class +klass+.
      def class_path(klass, root)
        path = const_to_path(klass, root)
        File.join(path, path.match(%r{/([^/]*)$})[1] << '.rb')
      end

      # Returns the path to a source file containing class +klass+.
      # Seatches across all common roots.
      def combined_class_path(klass)
        class_path(klass, @app_root ||= combined_app_root_glob)
      end

      # Returns the path to a directory containing class +klass+.
      # Seatches across all common roots.
      def combined_class_dir(klass)
        const_to_path(klass, @app_root ||= combined_app_root_glob)
      end

      # Returns an array with all common roots.
      def combined_app_root(include_gen_root=true)
        local_app_root = File.expand_path('../../../app', __FILE__)
        app_root = [@ctx_app_root ||= @context.app_root]
        app_root << @context.gen_root if include_gen_root
        app_root << local_app_root if local_app_root != @ctx_app_root
        app_root
      end

      # Returns a glob pattern of all common roots.
      def combined_app_root_glob(include_gen_root=true)
        "{#{combined_app_root(include_gen_root).join(',')}}"
      end

      # Returns a regexp pattern of all common roots.
      def combined_app_root_regexp(include_gen_root=true)
        regexp_root = '^('
        regexp_root << combined_app_root(include_gen_root).map do |dir|
          Regexp.escape(dir)
        end.join('|')
        regexp_root << ')/?'
        Regexp.new(regexp_root)
      end

      # Assigns a context to Tanuki::Loader.
      # This context should have common framework paths defined in it.
      def context=(ctx)
        @context = ctx
      end

      # Checks if +templates+ contain a compiled template +sym+
      # for class +klass+.
      def has_template?(templates, klass, sym)
        templates.include? "#{klass}##{sym}"
      end

      # Loads template +sym+.
      #
      # Template is recompiled from source on two conditions:
      # * Template source modification time is older than
      #   compiled template modification time,
      # * Tanuki::TemplateCompiler source modification time is older than
      #   compiled template modification time.
      def load_template(templates, obj, sym)
        owner, st_path = *resource_owner(obj.class, sym)
        if st_path
          ct_path = compiled_template_path(owner, sym)
          ct_file_exists = File.file?(ct_path)
          ct_file_mtime = ct_file_exists ? File.mtime(ct_path) : nil
          st_file = File.new(st_path, 'r:UTF-8')

          # Find out if template refresh is required
          if !ct_file_exists \
            || st_file.mtime > ct_file_mtime \
            || File.mtime(COMPILER_PATH) > ct_file_mtime
            no_refresh = compile_template(
              st_file, ct_path, ct_file_mtime, owner, sym
            )
          else
            no_refresh = true
          end

          # Load template
          method_name = (sym == 'view' ? sym : "#{sym}_view").to_sym
          owner.instance_eval do
            method_exists = instance_methods(false).include?(method_name)
            unless method_exists && no_refresh
              remove_method method_name if method_exists
              load ct_path
            end
          end

          # Register template in cache
          templates["#{owner}##{sym}"] = nil
          templates["#{obj.class}##{sym}"] = nil

          method_name
        else
          raise "undefined template `#{sym}' for #{obj.class}"
        end
      end

      def load_template_files(ctx, template_signature)
        klass_name, method = *template_signature.split('#')
        klass = klass_name.constantize
        method = method.to_sym
        _, path = *resource_owner(klass, method, JAVASCRIPT_EXT)
        ctx.javascripts[path] = false if path
        ctx.resources[template_signature] = nil
      end

      # Writes the compiled CSS file to disk
      # and refreshes with a given +interval+ in seconds.
      def refresh_css(interval=5)
        return if @next_reload && @next_reload > Time.new
        mode = File::RDWR|File::CREAT
        File.open("#{@context.public_root}/bundle.css", mode) do |f|
          f.flock(File::LOCK_EX) # Avoid race condition
          now = Time.new
          if !@next_reload || @next_reload < now
            @next_reload = now + interval
            @ctx_app_root ||= @context.app_root
            f.rewind
            compile_css(f, true)
            f.flush.truncate(f.pos)
          end # if
        end # open
      end

      # Prepares the application for production mode. This includes:
      # * precompiling all templates into memory,
      # * and prebuilding static file like the CSS bundle.
      def prepare_for_production
        root_glob = combined_app_root_glob(false)
        root_re = combined_app_root_regexp(false)

        # Load application modules
        path_re = /#{root_re}(?<path>.*)/
        Dir.glob(File.join(root_glob, "**/*")) do |file|
          if File.directory? file
            file.match(path_re) do |m|
              mod = File.join(file, File.basename(file)) << '.rb'
              if File.file? mod
                require mod
              else
                Object.const_set_recursive(m[:path].camelize, Module.new)
              end
            end # match
          end # if
        end

        # Load templates
        file_re = /#{root_re}(?<path>.*)\/.*\.(?<template>.*)\./
        Dir.glob(File.join(root_glob, "**/*#{TEMPLATE_EXT}")) do |file|
          file.match(file_re) do |m|
            ios = StringIO.new
            TemplateCompiler.compile_template(
              ios, File.read(file), m[:path].camelize, m[:template], false
            )
            m[:path].camelize.constantize.class_eval(ios.string)
          end # match
        end # glob

        # Load CSS
        css = CssCompressor.compress(compile_css(StringIO.new).string)
        Application.use(Rack::FrozenRoute, %r{/bundle.css}, 'text/css', css)
        Application.pull_down(Rack::StaticDir)
      end

      # Runs template +sym+ with optional +args+ and +block+
      # from object +obj+.
      def run_template(templates, obj, sym, *args, &block)
        method_name = load_template(templates, obj, sym)
        obj.send(method_name, *args, &block)
      end

      private

      # Path to Tanuki::TemplateCompiler for internal use.
      COMPILER_PATH = File.expand_path(
        '../template_compiler.rb',
        __FILE__
      ).freeze

      # Extension glob for template files.
      TEMPLATE_EXT = '.t{html,txt}'.freeze

      # Extension glob for JavaScript files.
      JAVASCRIPT_EXT = '.js'.freeze

      # Extension glob for CSS files.
      STYLESHEET_EXT = '.css'.freeze

      # Compiles all application stylesheets into +ios+.
      # Add path headers for each chunk of CSS if +mark_source+ is true.
      def compile_css(ios, mark_source=false)
        header = "/*** %s ***/\n"
        Dir.glob("#{@ctx_app_root}/**/*#{STYLESHEET_EXT}") do |file|
          if File.file? file
            ios << header % file.sub("#{@ctx_app_root}/", '') if mark_source
            ios << File.read(file) << "\n"
          end
        end
        ios
      end

      # Compiles template +sym+ from +owner+ class
      # using source in +st_file+ to +ct_path+.
      # Compilation is only done if destination file modification time
      # has not changed (is equal to +ct_file_mtime+)
      # since file locking was initiated.
      def compile_template(st_file, ct_path, ct_file_mtime, owner, sym)
        no_refresh = true

        # Lock template source to avoid race condition
        st_file.flock(File::LOCK_EX)

        # Compile, if template still needs compiling on lock release
        if !File.file?(ct_path) || File.mtime(ct_path) == ct_file_mtime
          no_refresh = false
          ct_dir = File.dirname(ct_path)
          FileUtils.mkdir_p(ct_dir) unless File.directory?(ct_dir)
          File.open(tmp_ct_path = ct_path + '~', 'w:UTF-8') do |ct_file|
            TemplateCompiler.compile_template(
              ct_file, st_file.read, owner, sym
            )
          end
          FileUtils.mv(tmp_ct_path, ct_path)
        end

        # Release lock
        st_file.flock(File::LOCK_UN)

        no_refresh
      end

      # Returns the path to a compiled template file
      # containing template +method_name+ for class +klass+.
      def compiled_template_path(klass, method_name)
        path = const_to_path(klass, @context.gen_root)
        "#{path}/#{method_name.to_s << '.tpl.rb'}"
      end

      # Transforms a given constant +klass+ to a path with a given +root+.
      def const_to_path(klass, root)
        path = klass.to_s.split('::').map(&:underscore).join('/').downcase
        "#{root}/#{path}"
      end

      # Finds the direct template +method_name+ owner
      # among ancestors of class +klass+.
      def resource_owner(klass, method_name, extension=TEMPLATE_EXT)
        klass.ancestors.each do |ancestor|
          path = const_to_path(ancestor, @app_root ||= combined_app_root_glob)
          method_file = ancestor.to_s.split('::')[-1].underscore.downcase
          method_file << '.' << method_name.to_s << extension
          files = Dir["#{path}/#{method_file}"]
          return ancestor, files[0] unless files.empty?
        end
        [nil, nil]
      end

    end # class << self

  end # Path

end # Tanuki
