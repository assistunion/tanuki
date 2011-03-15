module Tanuki

  # Tanuki::ModelBehavior contains basic methods for a framework model.
  # In is included in the base model class.
  module ModelBehavior

    # Creates new model with dataset row +data+.
    # If the model is +lazy+, +data+ should contain only row keys.
    def initialize(data={}, lazy=false)
      @_data = data
      @_loaded = !lazy
    end

    # Returns the value of a given attribute, loading the model on demand.
    def [](attribute)
      ensure_loaded! unless self.class[attribute].present_in(@_data)
      self.class[attribute].get(@_data)
    end

    # Sets the value of a given attribute.
    def []=(attribute, value)
      @_errors ||= {}
      @_original ||= {}
      begin
        unless @_original.include? attribute
          @_original[attribute] = self[attribute]
        end
        self.class[attribute].set(@_data, value)
        @_errors.delete(attribute)
      rescue
        @_errors[attribute] = {:value => value, :error => $!}
      end
    end

    # Returns the modification errors hash.
    def errors
      @_errors ||= {}
      @_errors
    end

    # Returns transport representation of data.
    def internals_get(attribute)
      self.class[attribute].internals_get(@_data)
    end

    # Sets transport representation of data.
    def internals_set(attribute, internal_value)
      @_errors ||= {}
      internals_set(self.class[attribute], @_data)
    end

    # Returns model updates hash.
    # This method is used internally to generate a data source update.
    def get_updates
      # TODO Rewrite this properly
      @_original ||= {}
      original_data = {}
      self.class.attributes.each_pair do |name, attrib|
        attrib.set(original_data, @_original[name])
      end
      updates = {}
      original_data.each_pair do |field, value|
        updates[field] = data[field] if data[field] != original_data[field]
      end
      updates
    end

    # Returns +true+ if there are any modification errors.
    def has_errors?
      @_errors ||= {}
      @_errors == {}
    end

    module ClassMethods

      # Returns meta-information for a given attribute.
      def [](attribute)
        @_attributes[attribute]
      end

      # Creates new model, or returns existing one.
      def get(data, ctx, lazy=false) # IDENTITY TRACKING AND LAZY LOADING
        entity_key = extract_key(data)
        key = [self, entity_key]
        # extract_key is generated ad-hoc by model compiler!
        if cached = ctx.entity_cache[key]
          cached
        else
          ctx.entity_cache[key] = get(*entity_key)
          # get is generated ad-hoc by model compiler
        end
      end

      # Assigns +attribute+ with definition +attr_def+ to model.
      def has_attribute(attribute, attr_def)
        @_attributes ||= superclass.instance_variable_get(:@_attributes).dup
        @_attributes[attribute] = attr_def
      end

      # Adds a relation +name+ with definition +relation_def+ to model.
      def has_relation(name, relation_def)
        @_relations ||= superclass.instance_variable_get(:@_relations).dup
        @_relations[name] = relation_def
      end

      # Prepares the extended module.
      def self.extended(mod)
        mod.instance_variable_set(:@_attributes, {})
        mod.instance_variable_set(:@_relations, {})
      end

    end # ClassMethods

    class << self

      # Extends the including module with Tanuki::ModelBehavior::ClassMethods.
      def included(mod)
        mod.extend ClassMethods
      end

    end # class << self

  end # ModelBehaviour

end # Tanuki
