module Tanuki

  # Tanuki::ModelGenerator is used for, well, generating models
  class ModelGenerator

    # A collection of all model definitions represented as hash of hashes
    # where the first nesting level represents namespaces
    # and the second one contains named model bodies hash.
    attr_reader :models

    # Hash for collecting the template render-time info for models.
    # Keys in this hash are full qualified names of models
    # (+namespace_model_name+). Base models are marked with +(base)+ suffix.
    # Values are hashes in the form of
    # +{:generated => [], :failed => [], :skipped => []}+
    # where all subentries correspond to template generation statuses.
    attr_reader :tried

    # Creates a model generator configured by given context +ctx+.
    def initialize(ctx)
      @ctx = ctx
      @tried = {}
      @models = {}
    end

    # Loads all models into memory from a given +schema_root+ and prepares
    # their own properties to be rendered in class templates.
    def read_models(schema_root)
      paths = Dir.entries(schema_root).reject {|path| path =~ /\A\..*\Z/ }
      paths.each do |namespace_path|
        namespace_name = namespace_path.camelize
        namespace = @models[namespace_name] = {}
        schema_glob = "#{schema_root}/#{namespace_path}/models/*.yml"
        p schema_glob
        Dir.glob(schema_glob) do |file_path|

          # Create meta model for namespace and model name from schema
          model_name = File.basename(file_path, '.yml').camelize
          meta_model = namespace[model_name] = Tanuki::MetaModel.new(
            namespace_name,
            model_name,
            YAML.load_file(file_path),
            @models
          )
          meta_model.process
          namespace_model_name = "#{namespace_name}.#{model_name}"

          # TODO is this necessary?
          next if @tried.include? namespace_model_name

          # Register namespace and model name
          @tried[namespace_model_name] = {
            :generated => [],
            :failed    => [],
            :skipped   => []
          }
          @tried["#{namespace_model_name} (base)"] = {
            :generated => [],
            :failed    => [],
            :skipped   => []
          }
        end # glob
      end # each
    end

    # Generates all models that were read from a given +schema_root+.
    # Generation paths are determined by context given in the constructor.
    def generate(schema_root)
      read_models schema_root
      process_models
      generate_classes
    end

    # Renders a model class by applying +class_type+ template
    # to a given +meta_model+. Classes are splitted in two parts:
    # * user-extendable part (+base=false+), which resides in +ctx.app_root+,
    # * other part with framework-specific code (+base=true+),
    # which resides in +ctx.gen_root+.
    # +namespace_model_name+ is used as a label for error report collection
    # in Tanuki::ModelGenerator#tried hash.
    def generate_class(meta_model, namespace_model_name, class_type, base)
      class_name = meta_model.class_name_for class_type
      namespace_model_name += ' (base)' if base
      root = base ? @ctx.gen_root : @ctx.app_root
      path = Tanuki::Loader.class_path(class_name, root)
      if base || !(File.exists? path)
        begin
          dirname = File.dirname(path)
          FileUtils.mkdir_p dirname unless File.directory? dirname
          File.open(path, 'w') do |file|
            writer = proc {|out| file << out.to_s }
            Loader.run_template({}, meta_model, class_type).call(writer, @ctx)
          end
          @tried[namespace_model_name][:generated] << class_name
        rescue
          @tried[namespace_model_name][:failed] << class_name
        end
      else
        @tried[namespace_model_name][:skipped] << class_name
      end
    end

    # Iterates over all loaded model definitions and renders
    # all available class templates for them.
    def generate_classes
      @models.each do |namespace_name, namespace |
        namespace.each do |model_name, meta_model|
          namespace_model_name = "#{namespace_name}.#{model_name}"
          {
            :model        => false,
            :model_base   => true,
            :manager      => false,
            :manager_base => true
          }.each do |class_type, base|
            generate_class meta_model, namespace_model_name, class_type, base
          end
        end
      end
    end

    # Iterates over all loaded model definitions, giving them a chance
    # to meet each other and make any cross-model assumptions
    # (like names for foreign keys).
    def process_models
      @models.each do |namespace_name, namespace |
        namespace.each do |model_name, meta_model|
          meta_model.process_relations
        end
      end
    end

  end # ModelGenerator

end # Tanuki
