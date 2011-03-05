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
        class_path(klass, @app_root ||= combined_app_root)
      end

      # Returns the path to a directory containing class +klass+.
      # Seatches across all common roots.
      def combined_class_dir(klass)
        const_to_path(klass, @app_root ||= combined_app_root)
      end

      # Returns a glob pattern of all common roots.
      def combined_app_root
        local_app_root = File.expand_path('../../../app', __FILE__)
        context_app_root = @context.app_root
        app_root = "{#{context_app_root},#{@context.gen_root}"
        app_root << ",#{local_app_root}" if local_app_root != context_app_root
        app_root << '}'
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
        owner, st_path = *template_owner(obj.class, sym)
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

      # Runs template +sym+ with optional +args+ and +block+
      # from object +obj+.
      def run_template(templates, obj, sym, *args, &block)
        method_name = load_template(templates, obj, sym)
        obj.send(method_name, *args, &block)
      end

      private

      # Path to Tanuki::TemplateCompiler for internal use.
      COMPILER_PATH = File.expand_path('../template_compiler.rb', __FILE__)

      # Extension glob for template files.
      TEMPLATE_EXT = '.t{html,txt}'

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
      def template_owner(klass, method_name)
        klass.ancestors.each do |ancestor|
          path = const_to_path(ancestor, @app_root ||= combined_app_root)
          method_file = ancestor.to_s.split('::')[-1].underscore.downcase
          method_file << '.' << method_name.to_s << TEMPLATE_EXT
          files = Dir.glob("#{path}/#{method_file}")
          return ancestor, files[0] unless files.empty?
        end
        [nil, nil]
      end

    end # class << self

  end # Path

end # Tanuki
