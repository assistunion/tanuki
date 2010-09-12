module Tanuki

  # Tanuki::ModelGenerator is used for, well, generating models
  class ModelGenerator

      attr_reader :tried, :models

      def initialize
        @tried = {}
        @models = {}
      end

      def generate(ctx)
        schema_root = ctx.schema_root
        Dir.entries(schema_root)[2..-1].each do |namespace_path|
          namespace_name = namespace_path.split('_').map {|s| s.capitalize }.join
          namespace = @models[namespace_name] = {}
          Dir.glob(File.join(schema_root, namespace_path, 'models', '*.yml')) do |file_path|
            model_name = File.basename(file_path, '.yml').split('_').map {|s| s.capitalize }.join
            meta_model = namespace[model_name] = Tanuki_MetaModel.new(
              namespace_name,
              model_name,
              YAML.load_file(file_path),
              @models
            )
            meta_model.process!
            if @tried.include? namespace_model_name = "#{namespace_name}.#{model_name}"
              next
            else
              @tried[namespace_model_name] = {:generated => [], :failed => [], :skipped => []}
            end
          end
        end

        @models.each do |namespace_name, namespace |
          namespace.each do |model_name, meta_model|
            meta_model.process_relations!
          end
        end

        @models.each do |namespace_name, namespace |
          namespace.each do |model_name, meta_model|
            namespace_model_name = "#{namespace_name}.#{model_name}"
            {
              :model => false,
              :model_base => true,
              :manager => false,
              :manager_base => true
            }.each do |class_type, base|
              class_name = meta_model.class_name_for class_type
              path = Tanuki::Loader.class_path(class_name, base ? ctx.gen_root : ctx.app_root)
              if base || !(File.exists? path)
                begin
                  dirname = File.dirname(path)
                  FileUtils.mkdir_p dirname unless File.directory? dirname
                  File.open path, 'w' do |file|
                    writer = proc {|out| file.print out.to_s }
                    Loader.run_template({}, meta_model, class_type).call(writer, ctx)
                  end
                  @tried[namespace_model_name][:generated] << class_name unless base
                rescue
                  @tried[namespace_model_name][:failed] << class_name unless base
                end
              else
                @tried[namespace_model_name][:skipped] << class_name unless base
              end
            end
          end
        end
      end

    end

end