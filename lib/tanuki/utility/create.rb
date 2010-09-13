module Tanuki

  module Utility

    @help[:create] = 'create a new app with the given name'

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
      file_source = File.expand_path(File.join('..', '..', '..', '..'), __FILE__)
      puts " creating #{File.join(name, 'app')}"
      FileUtils.mkdir_p File.join(project_dir, 'app', 'user')
      FileUtils.cp_r File.join(file_source, 'app', 'user'), File.join(project_dir, 'app')
      puts " creating #{File.join(name, 'gen')}"
      FileUtils.mkdir(gen_dir = File.join(project_dir, 'gen'))
      FileUtils.chmod(0777, gen_dir)
      puts " creating #{File.join(name, 'public')}"
      FileUtils.mkdir(File.join(project_dir, 'public'))
      puts " creating #{File.join(name, 'schema')}"
      FileUtils.mkdir(File.join(project_dir, 'schema'))
      Dir.chdir(project_dir) if @in_repl
    end

  end # end Utility

end # end Tanuki