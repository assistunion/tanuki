module Tanuki

  module Utility

    @help[:version] = 'show framework version'

    # Prints the running framework version.
    def self.version
      begin
        require 'tanuki/version'
      rescue LoadError
        $:.unshift File.expand_path(File.join('..', '..', '..'), __FILE__)
        require 'tanuki/version'
      end
      puts "Tanuki version #{VERSION}"
    end

  end # Utility

end # Tanuki