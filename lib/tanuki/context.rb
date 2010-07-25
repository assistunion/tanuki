module Tanuki
  class Context
    def child
      Class.new(self.class).new
    end

    def method_missing(sym, arg=nil)
      match = sym.to_s.match(/^([^=]+)(=)?$/)
      if match[2]
        if method_defined? match[1]
          self.class.instance_eval do
            if arg.is_a? Proc
              define_method(match[1], &arg)
            else
              define_method(match[1]) { arg }
            end
          end
          return arg
        else
          raise "context value `#{sym}' redefined, use Context#child"
        end
      end
      super
    end
  end
end