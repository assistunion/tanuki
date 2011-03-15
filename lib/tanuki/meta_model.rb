module Tanuki

  # Tanuki::MetaModel contains all methods for the meta-model.
  class MetaModel

    include Tanuki::BaseBehavior

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
      when :model, :model_base then "#{@namespace}::Model::#{@name}"
      when :manager, :manager_base then "#{@namespace}::Manager::#{@name}"
      end
    end

    # Returns an array of code for alias-column name pair.
    def key
      @key.inspect
    end

    # Prepares data for template generation.
    # Processes own keys, fields, etc.
    def process
      process_source
      process_key
      process_joins
      process_filter
      process_order
    end

    # Extracts the model firts-source information form the YAML @data
    # and performs
    def process_source
      guess_table = @name.pluralize
      @data ||= {}
      @source = @data['source'] || guess_table
      @source = {'table' => @source} if @source.is_a? String
      @first_source = (@source['table'] || guess_table).downcase.to_sym
    end

    def process_key
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
          if parts[0] != @first_source.to_s
            raise 'all key fields should belong to the first-source'
          end
          parts
        else
          [@first_source, parts[0]]
        end
      end
    end

    def process_joins
      @joins = {}
      @joins[@first_source] = nil
      joins = @source['joins'] || {}
      joins = [joins] if joins.is_a? String
      if joins.is_a? Array
        joins = Hash[*joins.collect {|v| [v, nil] }.flatten]
      end
      if joins.is_a? Hash
        joins.each_pair do |table_alias, join|
          table_alias = table_alias.to_sym
          if @joins.include? table_alias
            raise "#{table_alias} is already in use"
          end
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
            on.map! do |lhs, rhs|
              [
                [lhs, table_alias],
                [rhs, @first_source]
              ].map do |side, table_alias|
                if side.is_a? String
                  if m = side.match(/^\(('|")(.*)\1\)$/)
                    m[2]
                  else
                    parts = side.split('.').map {|x| x.to_sym }
                    case parts.count
                    when 1
                      [table_alias, parts[0]]
                    when 2
                      unless @joins.include? parts[0]
                        raise "unknown alias #{parts[0]}"
                      end
                      parts
                    else
                      raise "invalid column specification #{lhs}"
                    end # case
                  end # if match
                else
                  side
                end # if
              end # map
            end # map!
            on = Hash[*on.flatten]
          else
            on = {}
            @key.each do |k|
              on[[
                table_alias,
                (@first_source.to_s.singularize << '_' << k[1].to_s).to_sym
              ]] = k
            end # each
          end # if
          @joins[table_alias] = {
            :type => join_type,
            :table => table_name,
            :alias => table_alias,
            :on => on
          }
        end # each_pair
      else
        raise "`joins' should be either nil or string or array or hash"
      end # if
    end

    # Prepares data for building a Sequel +where+ clause.
    def process_filter
      # TODO
    end

    # Prepares data for building a Sequel +order+ clause.
    def process_order
      # TODO
    end

    # Prepares data for template generation.
    # Processes foreign keys, fields, etc.
    def process_relations
      # TODO
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

  end # MetaModel

end # Tanuki
