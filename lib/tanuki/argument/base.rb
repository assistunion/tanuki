module Tanuki
  module Argument
    class Base

      attr_accessor :value
      attr_reader :default

      def initialize(default)
        @value = @default = default
      end

      def set(s)
        @value = to_value(s)
        self
      end

    end # end Base
  end # end Argument
end # end Tanuki