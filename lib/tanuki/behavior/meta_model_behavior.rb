module Tanuki

  module MetaModelBehavior

      def initialize(namespace, name, data)
        @namespace = namespace
        @name = name
        @data = data
      end

      def class_name_for(class_type)
        case class_type
        when :model then "#{@namespace}_Model_#{@name}"
        when :model_base then "#{@namespace}_Model_#{@name}_#{@name}Base"
        when :manager then "#{@namespace}_Manager_#{@name}"
        when :manager_base then "#{@namespace}_Manager_#{@name}_#{@name}Base"
        end
      end

      def key
        if data['key'].nil?
          []
        elsif data['key'].is_a? Array
          data['key'].map {|item| qualified_name(item) }
        elsif data['key'].is_a? String
          [qualified_name(data['key'])]
        else
          raise "key for model #{@namespace}.#{@name} is invalid"
        end
      end

      def qualified_name(field_name)
        parts = field_name.split('.')
        if parts.length == 1
          ":#{field_name}"
        elsif parts.length == 2
          ":#{parts[1]}.qualify(:#{parts[0]}"
        else
          raise "field name for model #{@namespace}.#{@name} is invalid"
        end
      end

  end # end MetaModelBehavior

end # end Tanuki