module Tanuki
  module Argument

    # Tanuki::Argument::Base is the base class for argument types.
    class Base

      attr_reader :default, :value

      # Initializes the argument with a +default+ value.
      def initialize(default)
        @value = @default = default
      end

      # Returns a string representation of the argument value.
      def to_s
        @value.to_s
      end

      # Sets the value to +obj+ with required rules.
      def value=(obj)
        @value = to_value(obj)
      end

    end # end Base

  end # end Argument
end # end Tanuki