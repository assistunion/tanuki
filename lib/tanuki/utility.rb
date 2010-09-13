module Tanuki

  module Utility

    class << self

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

      def init
        @in_repl = false
        @commands = []
        @help = {}
        Dir.glob(File.expand_path(File.join('..', 'utility', '*.rb'), __FILE__)) do |file|
          if match = file.match(/\/([^\/]+).rb/)
            require file
            @commands << match[1].to_sym
          end
        end
        execute ARGV
      end

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