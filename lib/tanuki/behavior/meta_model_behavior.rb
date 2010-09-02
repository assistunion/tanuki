module Tanuki

  # Tanuki::MetaModelBehavior contains all methods for the meta-model.
  # In is included in the meta-model class.
  module MetaModelBehavior

      # Creates new meta-model +name+ in +namespace+.
      # Model schema is passed as +data+.
      def initialize(namespace, name, data)
        @namespace = namespace
        @name = name
        @data = data
        @joins = {}

        # Configuring source
        @source = @data['source'] || guess_table
        if @source.is_a? String
          @first_source = @source.to_sym
          joins = {}
          key = 'id'
        else
          @first_source = (@source['table'] || guess_table).to_sym
          joins = @source['joins'] || {}
          key = @source['key'] || 'id'
        end

        key = [key] if key.is_a? String
        @joins[@first_source] = nil

        joins = [joins] if joins.is_a? String
        joins = Hash[*joins.collect {|v| [v, nil] }.flatten] if joins.is_a? Array

        if joins.is_a? Hash
          joins.each_pair do |table_alias, join|
            table_alias = table_alias.to_sym
            raise "#{table_alias} is already in use" if @joins.include? table_alias

            if joins && joins['on'].is_a Hash
              table_name = joins['table'] || table_alias
            else
               on = joins
               table_name = table_alias
            end
          end
          j  = {}
          joins[table_alias] = j
        else
          raise "Something went wrong!"
        end


      end

      # Returns class name for a given class type.
      def class_name_for(class_type)
        case class_type
        when :model, :model_base then "#{@namespace}_Model_#{@name}"
        when :manager, :manager_base then "#{@namespace}_Manager_#{@name}"
        end
      end

      # Returns default source, if none specified.
      def guess_table
        @name.pluralize
      end

      # Returns default key, if none specified.
      def guess_key
        ["%w{:#{@first_source} :id}"]
      end

      # Returns an array of code for alias-column name pair.
      def key
        if @data['key'].nil?
          guess_key
        elsif @data['key'].is_a? Array
          @data['key'].map {|item| qualified_name(item) }
        elsif @data['key'].is_a? String
          [qualified_name(@data['key'])]
        else
          raise "key for model #{@namespace}.#{@name} is invalid"
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