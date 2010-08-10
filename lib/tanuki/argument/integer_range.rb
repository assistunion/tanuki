module Tanuki
  module Argument
    class IntegerRange < Integer

      def initialize(default, range)
        super(default)
        @range = range
      end

      def to_value(s)
        i = super(s)
        @range.include?(i) ? i : @default
      end

    end # end IntegerRange
  end # end Argument
end # end Tanuki