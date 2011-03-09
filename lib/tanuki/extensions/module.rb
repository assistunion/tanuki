class Module

  # Runs Tanuki::Loader for every missing constant in any namespace.
  def const_missing(sym)
    klass = "#{name + '::' unless name.nil? || (name == 'Object')}#{sym}"
    paths = Dir.glob(Tanuki::Loader.combined_class_path(klass))
    if paths.empty?
      unless Dir.glob(Tanuki::Loader.combined_class_dir(klass)).empty?
        return const_set(sym, Module.new)
      end
    else
      paths.reverse_each {|path| require path }
      return const_get(sym) if const_defined?(sym)
    end
    raise NameError, "uninitialized constant #{name}::#{sym}"
  end

  # Creates a reader +sym+ and a writer +sym=+
  # for the instance variable @_sym.
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
