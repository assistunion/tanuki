module Tanuki
  module Argument

    # Tanuki::Argument::IntegerRange is a class for +Integer+ arguments with
    # a certain value range.
    class IntegerRange < Integer

      # Initializes the argument with a +default+ value and allowed value
      # +range+.
      def initialize(range, default=nil)
        super(default ? default : range.first)
        @range = range
      end

      # Returns argument value from an object +obj+.
      def to_value(obj)
        i = super(obj)
        @range.include?(i) ? i : @default
      end

    end # IntegerRange

  end # Argument
end # Tanuki
