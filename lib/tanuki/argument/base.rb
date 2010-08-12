module Tanuki
  module Argument

    # Tanuki::Argument::Base is the base class for argument types.
    class Base

      attr_accessor :value
      attr_reader :default

      # Initializes the argument with a default value.
      def initialize(default)
        @value = @default = default
      end

      # Sets the argument value from a string representation.
      def parse(s)
        @value = to_value(s)
        self
      end

      # Sets the argument value to a given object.
      def set(obj)
        @value = obj
        self
      end

      # Returns a string representation of the argument value.
      def to_s
        @value.to_s
      end

    end # end Base

  end # end Argument
end # end Tanuki