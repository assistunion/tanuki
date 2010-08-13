module Tanuki
  module Argument

    # Tanuki::Argument::Integer is a class for Integer arguments.
    class Integer < Base

      # Returns argument value from a string representation.
      def to_value(obj)
        begin Kernel::Integer obj rescue @default end
      end

    end # end Integer

  end # end Argument
end # end Tanuki