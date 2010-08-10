module Tanuki
  module Argument
    class Integer < Base

      def to_value(s)
        @value = begin Integer s rescue @default end
      end

    end # end Integer
  end # end Argument
end # end Tanuki