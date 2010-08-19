class Object

  # Runs Tanuki::Loader for every missing constant in main namespace.
  def self.const_missing(sym)
    if File.file?(path = Tanuki::Loader.class_path(sym))
      require path
      return const_get(sym)
    end
    super
  end

end # end Object