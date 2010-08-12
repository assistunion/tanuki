module Tanuki
  module Argument

    # Tanuki::Argument::Integer is a class for Integer arguments.
    class Integer < Base

      # Returns argument value from a string representation.
      def to_value(s)
        begin Integer s rescue @default end
      end

    end # end Integer

  end # end Argument
end # end Tanuki