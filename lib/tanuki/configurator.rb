module Tanuki
  class Configurator
    def self.set(option, value)
      Application.set(option, value)
    end

    def self.use(middleware, *args, &block)
      Application.use(middleware, *args, &block)
    end

    def self.visitor(sym, &block)
      Application.visitor(sym, &block)
    end
  end
end