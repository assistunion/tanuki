class Module

  # Runs Tanuki::Loader for every missing constant in any namespace.
  def const_missing_with_tanuki(const)
    paths = Dir.glob(Tanuki::Loader.combined_class_path(sym))
    unless paths.empty?
      paths.reverse_each {|path| require path }
      return const_defined?(const) ? const_get(const) : super
    end
    super
  end

  alias_method_chain :const_missing, :tanuki

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

end # Module
