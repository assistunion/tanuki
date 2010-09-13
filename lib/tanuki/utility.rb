module Tanuki

  # Tanuki::Utility is a collection of methods for the framework console.
  # The actual script is located in +bin/tanuki+ in gem or source location.
  # An executable +tanuki+ is installed with the gem.
  module Utility

    class << self

      # Executes given +args+.
      # The first item in +args+ is the name of a command, and the rest are arguments for the command.
      def execute(args)
        case args[0]
        when 'exit' then @in_repl ? (puts 'Bye bye!'; return false) : help
        when nil then start_repl unless @in_repl
        else
          if @commands.include? args[0].to_sym
            begin
              method(args[0].to_sym).call(*args[1..-1])
            rescue ArgumentError => e
              puts e.message.capitalize
            end
          else
            help
          end
        end
        true
      end

      # Initializes the utility state and loads command methods.
      # Executes the utility with +ARGV+.
      def init
        @in_repl = false
        @commands = []
        @help = {}
        Dir.glob(File.expand_path(File.join('..', 'utility', '*.rb'), __FILE__)) do |file|
          if match = file.match(/\/([^\/]+).rb/)
            require file
            command = match[1].to_sym
            @commands << command
            @help[command] = nil unless @help.include? command
          end
        end
        execute ARGV
      end

      # Starts a REPL (framework console).
      # In this console +command [args]+ call is equivalent to +tanuki command [args]+ in the terminal.
      def start_repl
        @in_repl = true
        @help[:exit] = 'exit this utility'
        version
        print 'tanuki>'
        begin
          print "\ntanuki>" while gets && execute($_.chomp.scan /(?<=")[^"]*(?=")|[^\s]+/)
        rescue Interrupt
          puts "\nBye bye!"
        end
      end

    end # end class << self

  end # end Utility

end # end Tanuki