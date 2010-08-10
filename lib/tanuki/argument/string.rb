module Tanuki
  module Argument
    class String < Base

      def to_value(s)
        @value = s.to_s
      end

    end # end String
  end # end Argument
end # end Tanuki