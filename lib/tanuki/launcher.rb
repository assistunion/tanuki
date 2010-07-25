module Tanuki
  class Launcher
    def initialize(ctrl, ctx)
      @ctrl = ctrl
      @ctx = ctx
    end

    def each(&block)
      @ctrl.default_view.call(proc {|out| block.call(out.to_s) }, @ctx)
    end
  end
end