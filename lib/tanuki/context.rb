module Tanuki

  # Tanuki::Context is used to create unique environments for each request.
  # Once a context variable has been set, it cannot be redefined.
  # Child contexts are used to override parent context variables without changing them directly.
  # Use Tanuki::Context#child to create new contexts.
  class Context

    # Create and return child context.
    def child
      Class.new(self.class).new
    end

    # Object#method_missing hook.
    def method_missing(sym, arg=nil)
      match = sym.to_s.match(/^([^=]+)(=)?$/)
      self.class.instance_eval do
        method_sym = match[1].to_sym
        unless instance_methods(false).include? method_sym
          if arg.is_a? Proc
            define_method(method_sym, &arg)
          else
            define_method(method_sym) { arg }
          end
          return arg
        else
          raise "context entry `#{match[1]}' redefined, use Context#child"
        end
      end if match[2]
      super
    end

  end # end Context

end # end Tanuki