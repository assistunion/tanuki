module Rack
  class Builder

    # Initializes application settings using configuration for environment +env+ and +rackup+ arguments.
    # Application is configured for production, if no environment is specified.
    # Returns Tanuki::Application::rack_app.
    #
    # This should be invoked from Rackup configuration files (e.g. +config.ru+):
    #
    #   #\ -p 3000
    #   require 'tanuki'
    #   run tanuki
    def tanuki(env=nil)
      puts %{Calling for a Tanuki in "#{Dir.pwd}"}
      at_exit { puts 'Tanuki ran away!' }
      builder = self
      Tanuki::Application.instance_eval do
        configure(env ? env.to_sym : :production)
        configure_middleware(builder)
        puts "A wild Tanuki appears!"
        rack_app
      end
    end

  end # end
end # end Rack