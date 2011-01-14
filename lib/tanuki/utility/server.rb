module Tanuki

  module Utility

    @help[:server] = 'run application'

    # Runs the application in the current directory and environment +env+.
    def self.server(env=nil)
      env = env ? env.to_sym : :development
      puts %{Calling for a Tanuki in "#{Dir.pwd}"}
      version unless @in_repl
      require 'tanuki'
      begin
        Application.run
        puts 'Tanuki ran away!'
      rescue SystemCallError
        puts 'Tanuki ran away! Someone else is playing here.'
      end if Application.configure(env)
    end

  end # Utility

end # Tanuki
