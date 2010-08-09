module Tanuki

  # Tanuki::I18n is a drop-in controller for localizable applications.
  class I18n

    include ControllerBehavior

    # Adds language routes of root controller class when invoked.
    def configure
      root_page = @_ctx.root_page
      @_ctx.languages.each {|lng| has_child root_page, lng }
    end

    # Returns default route according to default language.
    def default_route
      {:route => @_ctx.language.to_s, :args => {}}
    end

    # Calls default view of visual child.
    def default_view
      @_visual_child.default_view
    end

    # Adds child language to its context.
    def process_child_context(ctx, route)
      ctx = ctx.child
      ctx.language = route.to_sym
      ctx
    end

  end # end I18n

end # end Tanuki