class Object

  # Runs Tanuki::Loader for every missing constant in main namespace.
  def self.const_missing(sym)
    unless (paths = Dir.glob(Tanuki::Loader.combined_class_path(sym))).empty?
      paths.reverse_each {|path| require path }
      return const_get(sym)
    end
    super
  end

end # Object