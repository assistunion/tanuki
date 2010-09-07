module Tanuki

  # Tanuki::Context is used to create unique environments for each request.
  # Child contexts inherit parent context entries and can override them without modifying the parent context.
  # Use Tanuki::Context::child to create new contexts.
  class Context

    @_defined = {}

    class << self

      # Creates and returns child context object.
      # This object's superclass is going to be current context class.
      def child
        child = Class.new(self)
        child.instance_variable_set(:@_defined, {})
        child
      end

      # Returns a printable version of Tanuki::Context, represented as a +Hash+.
      # Can be used during development for inspection purposes.
      #--
      # When changing this method, remember to update `#{__LINE__ + 12}' to `defined.inspect` line number.
      # This is required to avoid infinite recursion.
      def inspect
        return to_s if caller.any? {|entry_point| entry_point =~ /\A#{__FILE__}:#{__LINE__ + 12}/}
        defined = {}
        ancestors.each do |ancestor|
          ancestor.instance_variable_get(:@_defined).each_key do |key|
            begin
              defined[key] ||= send(key)
            rescue ArgumentError
              defined[key] ||= method(key)
            end
          end
          break if ancestor.equal? Context
        end
        defined.inspect
      end

      # Allowes arbitary values to be assigned to context with a +key=+ method.
      # A reader in context object class is created for each assigned value.
      def method_missing(sym, arg=nil)
        match = sym.to_s.match(/\A(?!(?:child|inspect|method_missing)=\Z)([^=]+)(=)?\Z/)
        raise "`#{sym}' method cannot be called for Context and its descendants" unless match
        defined = @_defined
        class << self; self; end.instance_eval do
          method_sym = match[1].to_sym
          if defined.include? method_sym
            undef_method method_sym
          else
            defined[method_sym] = nil
          end
          if arg.is_a? Proc
            define_method(method_sym, &arg)
          else
            define_method(method_sym) { arg }
          end
          return arg
        end if match[2]
        super
      end

      # Disallow context instantiation
      def new
        raise "contexts cannot be instantiated"
      end

    end # end class << self

  end # end Context

end # end Tanuki