module Tanuki

  # Tanuki::MetaModelBehavior contains all methods for the meta-model.
  # In is included in the meta-model class.
  module MetaModelBehavior

      # Creates new meta-model +name+ in +namespace+.
      # Model schema is passed as +data+.
      # Stucture +models+ contains all models being generated.
      def initialize(namespace, name, data, models)
        @namespace = namespace
        @name = name
        @data = data
        @models = models
      end

      # Returns class name for a given class type.
      def class_name_for(class_type)
        case class_type
        when :model, :model_base then "#{@namespace}_Model_#{@name}"
        when :manager, :manager_base then "#{@namespace}_Manager_#{@name}"
        end
      end

      # Returns an array of code for alias-column name pair.
      def key
        @key.inspect
      end

      # Prepares data for template generation.
      # Processes own keys, fields, etc.
      def process!
        process_source!
        process_key!
      end

      def process_key!
        @key = @source['key'] || 'id'
        @key = [key] if key.is_a? String
        raise "invalid key" unless @key.is_a? Array
        @key.map! do |k|
          parts = k.split('.').map {|p| p.to_sym }
          raise "invalid key field #{k}" if parts.count > 2
          if parts.count = 2
            raise "all key fields should belong to the first-source" if parts[0] != @first_source.to_s
            parts
          else
            [@first_source,parts[0]]
          end
        end
      end

      # Extracts the model firts-source information form the YAML @data
      # and performs
      def process_source!
        guess_table = @name.pluralize
        @source = @data['source'] || guess_table
        @source = {'table' => @source} if @source.is_a? String
        @first_source = (@source['table'] || guess_table).to_sym
      end

      def process_joins!
        @joins = {}
        @joins[@first_source] = nil
      end

      # Prepares data for template generation.
      # Processes foreign keys, fields, etc.
      def process_relations!

        joins = @source['joins'] || {}
        joins = [joins] if joins.is_a? String
        joins = Hash[*joins.collect {|v| [v, nil] }.flatten] if joins.is_a? Array
        if joins.is_a? Hash
          joins.each_pair do |table_alias, join|
            table_alias = table_alias.to_sym
            raise "#{table_alias} is already in use" if @joins.include? table_alias
            if join
              if join['on'].is_a Hash
                table_name = join['table'] || table_alias
                on = join['on']
              else
                on = join
                table_name = table_alias
              end
            else
               on = nil
               table_name = table_alias
            end
            if on
            else
              on = {}
              @key.each do |k|
                on[[table_alias, @first_source.to_s.singularize.to_sym]] = [] # TODO choose a right priciple
              end
            end
          end
          j  = {}
          joins[table_alias] = j
        else
          raise "`joins' should be either nil or string or array or hash"
        end
      end

      # Returns code for alias-column name pair for field +field_name+.
      def qualified_name(field_name)
        parts = field_name.split('.')
        if parts.length == 1
          "%w{:#{@first_source} :#{field_name}}"
        elsif parts.length == 2
          "%w{:#{parts[0]} :#{parts[1]}}"
        else
          raise "field name for model #{@namespace}.#{@name} is invalid"
        end
      end

  end # end MetaModelBehavior

end # end Tanuki