require File.join('tanuki', 'argument', 'base')
require File.join('tanuki', 'argument', 'integer')
require File.join('tanuki', 'argument', 'integer_range')
require File.join('tanuki', 'argument', 'string')

module Tanuki

  # Tanuki::Argument contains basic classes and methods for controller arguments.
  module Argument

    @assoc = {}

    class << self

      # Removes argument association for a given type class +klass+.
      def delete(klass)
        @assoc.delete(klass)
      end

      # Associates a given type class +klass+ with an argument class +arg_class+.
      def store(klass, arg_class)
        warn "Tanuki::Argument::Base is not an ancestor of `#{arg_class}'" unless arg_class.ancestors.include? Argument::Base
        @assoc[klass] = arg_class
      end

      alias_method :[], :store

      # Converts a given type object +obj+ to an argument object with optional +args+.
      def to_argument(obj, *args)
        if @assoc.include?(klass = obj.class)
          @assoc[klass].new(obj, *args)
        else
          Argument::String.new(obj.to_s)
        end
      end

    end # end class << self

  end # end Argument

end # end Tanuki