module Tanuki

  module Utility

    @help[:version] = 'show framework version'

    # Prints the running framework version.
    def self.version
      require 'tanuki/version'
      puts "Tanuki version #{Tanuki.version}"
    end

  end # Utility

end # Tanuki
