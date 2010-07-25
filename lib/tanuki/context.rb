module Tanuki
  class Context
    def child
      Class.new(self.class).new
    end

    def method_missing(sym, arg=nil)
      match = sym.to_s.match(/^([^=]+)(=)?$/)
      self.class.instance_eval do
        unless instance_methods(false).include? match[1]
          if arg.is_a? Proc
            define_method(match[1], &arg)
          else
            define_method(match[1]) { arg }
          end
          return arg
        else
          raise "context entry `#{match[1]}' redefined, use Context#child"
        end
      end if match[2]
      super
    end
  end
end