module Tanuki
  module Argument

    # Tanuki::Argument::String is a class for +String+ arguments.
    class String < Base

      # Returns argument value from an object +obj+.
      def to_value(obj)
        obj.to_s
      end

    end # String

  end # Argument
end # Tanuki
