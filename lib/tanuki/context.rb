module Tanuki

  # Tanuki::Context is used to create unique environments for each request.
  # Once a context variable has been set, it cannot be redefined.
  # Child contexts are used to override parent context variables without changing them directly.
  # Use Tanuki::Context#child to create new contexts.
  class Context

    # Creates and returns child context object.
    # This object's superclass is going to be current context class.
    def child
      Class.new(self.class).new
    end

    # Allowes arbitary values to be assigned to context with a +key=+ method.
    # A reader in context object class is created for each assigned value.
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
      warn "#{__FILE__}:#{__LINE__}: warning: undefined context entry `#{sym}' for #{self}"
      super
    end

  end # end Context

end # end Tanuki