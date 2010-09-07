class Module

  # Behaves like +alias_method_chain+ from Rails.
  # Encapsulates the common pattern of:
  #
  #   alias_method :foo_without_feature, :foo
  #   alias_method :foo, :foo_with_feature
  #
  # With this, you simply do:
  #
  #   alias_method_chain :foo, :feature
  def alias_method_chain(target, feature)
    name, tail = target.to_s.sub(/([?!=])$/, ''), $1
    yield(name, tail) if block_given?
    with = "#{name}_with_#{feature}#{tail}"
    without = "#{name}_without_#{feature}#{tail}"
    alias_method without, target
    alias_method target, with
    if public_method_defined?(without)
      public target
    elsif protected_method_defined?(without)
      protected target
    elsif private_method_defined?(without)
      private target
    end
  end

  # Creates a reader +sym+ and a writer +sym=+ for the instance variable @_sym.
  def internal_attr_accessor(*syms)
    internal_attr_reader(*syms)
    internal_attr_writer(*syms)
  end

  # Creates a reader +sym+ for the instance variable @_sym.
  def internal_attr_reader(*syms)
    syms.each do |sym|
      ivar = "@_#{sym}".to_sym
      instance_variable_set(ivar, nil) unless instance_variable_defined? ivar
      class_eval "def #{sym};#{ivar};end"
    end
  end

  # Creates a writer +sym=+ for the instance variable @_sym.
  def internal_attr_writer(*syms)
    syms.each do |sym|
      ivar = "@_#{sym}".to_sym
      instance_variable_set(ivar, nil) unless instance_variable_defined? ivar
      class_eval "def #{sym}=(obj);#{ivar}=obj;end"
    end
  end

end # end Module