module Tanuki

  module Utility

    @help[:create] = 'create a new app with the given name'

    # Creates a new application with a given +name+.
    def self.create(name=nil)
      unless name
        puts "To use this command: `create <name>'"
        return
      end
      require 'fileutils'
      project_dir = File.expand_path(name)
      if File.exists? project_dir
        puts "File or directory `#{name}' already exists!"
        return
      end
      version unless @in_repl
      puts "\n creating #{name = name.downcase}"
      FileUtils.mkdir project_dir
      file_source = File.expand_path('../../../..', __FILE__)
      puts " creating #{name}/app"
      FileUtils.mkdir_p "#{project_dir}/app/user"
      FileUtils.cp_r "#{file_source}/app/user", "#{project_dir}/app"
      puts " creating #{name}/gen"
      FileUtils.mkdir(gen_dir = "#{project_dir}/gen")
      FileUtils.chmod(0777, gen_dir)
      puts " creating #{name}/public"
      FileUtils.mkdir("#{project_dir}/public")
      puts " creating #{name}/schema"
      FileUtils.mkdir("#{project_dir}/schema")
      Dir.chdir(project_dir) if @in_repl
    end

  end # Utility

end # Tanuki
