module Tanuki

  module ModelBehavior

    def initialize(data = {}, lazy = false)
      @_data = data
      @_loaded = not lazy
    end

    def [](attribute)
      ensure_loaded!
      self.class[attribute].get @_data
    end

    def []=(attribute, value)
      @_errors ||= {}
      @_original ||= {}
      begin
        @_original[attribute] = self[attribute] unless @_original.include? attribute
        self.class[attribute].set @_data, value
        @_errors.delete attribute
      rescue
        @_errors[attribute] = {:value => value, :error => $!}
      end
    end


    def internals_get(attribute)
      self.class[attribute].internals_get @_data
    end

    def internals_set(attribute, internal_value)
      @_errors ||={}
      self.class[attribute], internals_set @_data
    end

    def get_updates
      @_original ||= {}
      original_data = {}
      class.attributes.each_pair do |name, attr|
        attr.set original_data, @_original[name]
      end
      updates = {}
      original_data.each_pair do |field, value|
        updates[field] = data[field] if data[field] != original_data[field]
      end
      updates
    end

    def get_error(attribute)
      @_errors ||= {}
      @_errors[attribute]
    end

    def invalid?(attribute)
      @_errors.include? attribute
    end

    def has_errors?
      @_errors ||= {}
      @_errors == {}
    end

    def errors
      @_errors ||= {}
      @_errors
    end

    module ClassMethods

      def create(data, ctx, lazy = false) # IDENTITY TRACKING AND LAZY LOADING
        entity_key = extract_key(data)
        key = [self, entity_key] #extract_key is generated ad hoc by model compiler!
        if cached = ctx.entity_cache[key]
          cached
        else
          ctx.entity_cache[key] = get(*entity_key) # get is generated Ad Hoc by model compiler
        end
      end


      def has_attribute(attribute, attr_def)
        @_attributes ||= superclass.instance_variable_get(:@_attributes).dup
        @_attributes[attribute] = attr_def
      end
      def [](attribute)
        @_attributes[attribute]
      end

      def has_reference(attribute, reference_def)
        @_references ||= superclass.instance_variable_get(:@_references).dup
        @_references[attribute] = reference_def
      end

      # Prepares the extended module.
      def self.extended(mod)
        mod.instance_variable_set(:@_attributes, {})
        mod.instance_variable_set(:@_references, {})
      end

    end # end ClassMethods

    class << self

      def included(mod)
        mod.extend ClassMethods
      end

    end # end class << self

  end # end ModelBehaviour

end # end Tanuki