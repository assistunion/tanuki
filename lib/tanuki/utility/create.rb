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
      puts "Creating `#{name}'\n"
      FileUtils.mkdir project_dir
      file_source = File.expand_path('../../../..', __FILE__)
      name_pos = ((file_source.length + 1)..-1)

      # ./app/
      puts '  app/'
      FileUtils.mkdir "#{project_dir}/app"
      puts '  app/user/'
      FileUtils.mkdir "#{project_dir}/app/user"
      Dir["#{file_source}/app/user/**/*"].each do |file|
        is_dir = File.directory? file
        puts "  #{file[name_pos]}#{'/' if is_dir}"
        if is_dir
          FileUtils.mkdir("#{project_dir}/#{file[name_pos]}")
        else
          FileUtils.cp(file, "#{project_dir}/#{file[name_pos]}")
        end
      end

      # ./gen/
      puts '  gen/'
      FileUtils.mkdir(gen_dir = "#{project_dir}/gen")
      FileUtils.chmod(0777, gen_dir)

      # ./public/
      puts '  public/'
      FileUtils.mkdir("#{project_dir}/public")

      # ./schema/
      puts '  schema/'
      FileUtils.mkdir("#{project_dir}/schema")

      # ./config.ru
      puts '  config.ru'
      File.open("#{project_dir}/config.ru", 'w') do |f|
        f << "require 'bundler'\nBundler.require\n" <<
             "run Tanuki::Application.build(self)\n"
      end

      # ./Gemfile
      puts '  Gemfile'
      File.open("#{project_dir}/Gemfile", 'w') do |f|
        f << "source :rubygems\ngem 'tanuki', '~> #{Tanuki.version}'\n"
      end

      # ./README.rdoc
      puts '  README.rdoc'
      File.open("#{project_dir}/README.rdoc", 'w') do |f|
        f << "= #{title = name.titleize}\n\n" <<
             "#{title} is a " <<
             "{Tanuki}[https://assistunion.com/sharing] application.\n"
      end

      Dir.chdir(project_dir) if @in_repl
    end

  end # Utility

end # Tanuki
