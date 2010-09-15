module Tanuki

  # Tanuki::Launcher is called on every request.
  # It is used to build output starting with the default view of the root controller.
  # Rack iterates over an instance of this object on every request.
  class Launcher

    # Creates a new Tanuki::Launcher with root controller +ctrl+ in context +ctx+.
    def initialize(ctrl, ctx)
      @ctrl = ctrl
      @ctx = ctx
    end

    # Passes a given +block+ to the requested page template tree.
    def each(&block)
      @ctrl.default_view.call(proc {|out| block.call(out.to_s) }, @ctx)
    end

  end # Launcher

end # Tanuki