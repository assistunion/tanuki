module Tanuki

  module Utility

    @help[:version] = 'show framework version'

    def self.version
      begin
        require 'tanuki/version'
      rescue LoadError
        $:.unshift File.expand_path(File.join('..', '..', '..'), __FILE__)
        require 'tanuki/version'
      end
      puts "Tanuki version #{VERSION}"
    end

    def self.version_help
    end

  end # end Utility

end # end Tanuki