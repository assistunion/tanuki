module Tanuki
  module Argument

    # Tanuki::Argument::String is a class for String arguments.
    class String < Base

      # Returns argument value from a string representation.
      def to_value(s)
        s.to_s
      end

    end # end String

  end # end Argument
end # end Tanuki