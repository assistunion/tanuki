module Tanuki

  module Utility

    @help[:help] = 'show help (this text)'

    # Shows help for all available commands.
    def self.help
      version unless @in_repl
      puts "\nbasic commands:\n"
      @help.each_pair {|k, v| puts ' %-8s   %s' % [k, v] }
    end

  end # end Utility

end # end Tanuki