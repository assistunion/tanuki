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
        process_joins!
        process_filter!
        process_order!
      end

      # Prepares data for building a Sequel +where+ clause.
      def process_filter!
        # TODO: ...
      end

      def process_key!
        if @source.include? 'key' && @source['key'].nil?
          @key = []
        else
          @key = @source['key'] || 'id'
        end
        @key = [@key] if @key.is_a? String
        raise 'invalid key' unless @key.is_a? Array
        @key.map! do |k|
          parts = k.split('.').map {|p| p.to_sym }
          raise "invalid key field #{k}" if parts.count > 2
          if parts.count == 2
            raise 'all key fields should belong to the first-source' if parts[0] != @first_source.to_s
            parts
          else
            [@first_source, parts[0]]
          end
        end
      end

      # Prepares data for building a Sequel +order+ clause.
      def process_order!
        # TODO: ...
      end

      # Extracts the model firts-source information form the YAML @data
      # and performs
      def process_source!
        guess_table = @name.pluralize
        @data ||= {}
        @source = @data['source'] || guess_table
        @source = {'table' => @source} if @source.is_a? String
        @first_source = (@source['table'] || guess_table).downcase.to_sym
      end

      def process_joins!
        @joins = {}
        @joins[@first_source] = nil
        joins = @source['joins'] || {}
        joins = [joins] if joins.is_a? String
        joins = Hash[*joins.collect {|v| [v, nil] }.flatten] if joins.is_a? Array
        if joins.is_a? Hash
          joins.each_pair do |table_alias, join|
            table_alias = table_alias.to_sym
            raise "#{table_alias} is already in use" if @joins.include? table_alias
            if join && (join['on'].is_a? Hash)
              table_name = join['table'] || table_alias
              on = join['on']
              join_type = (join['type'] || 'inner').to_sym
            else
              on = join
              table_name = table_alias
              join_type = :inner
            end
            if on
              on = Hash[*on.map do |lhs, rhs|
                [[lhs,table_alias],[rhs,@first_source]].map do |side,table_alias|
                  if side.is_a? String
                    if m = side.match(/^\(('|")(.*)\1\)$/)
                      m[2]
                    else
                      parts = side.split('.').map {|x| x.to_sym }
                      case parts.count
                      when 1
                        [table_alias, parts[0]]
                      when 2
                        raise "Unknown alias #{parts[0]}" unless @joins.include? parts[0]
                        parts
                      else
                        raise "Invalid column specification #{lhs}"
                      end
                    end
                  else
                    side
                  end
                end
              end.flatten]
            else
              on = {}
              @key.each do |k|
                on[[table_alias, (@first_source.to_s.singularize << '_' << k[1].to_s).to_sym]] = k
              end
            end
            @joins[table_alias] = {
              :type => join_type,
              :table => table_name,
              :alias => table_alias,
              :on => on
            }
          end
        else
          raise "`joins' should be either nil or string or array or hash"
        end
      end

      # Prepares data for template generation.
      # Processes foreign keys, fields, etc.
      def process_relations!

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

  end # MetaModelBehavior

end # Tanuki