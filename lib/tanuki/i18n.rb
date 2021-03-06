module Tanuki

  # Tanuki::I18n is a drop-in controller for localizable applications.
  class I18n < Controller

    # Adds language routes of root controller class when invoked.
    def configure
      raise 'languages are not configured' if @_ctx.languages.size == 0
      root = @_ctx.autoconfiguration[:root]
      @_ctx.languages.each do |lng|
        has_child root[:controller], lng, root
      end
    end

    # Returns default route according to default language.
    def default_route
      raise 'default language is not configured' unless @_ctx.language
      {
        :route    => @_ctx.language,
        :args     => {},
        :redirect => @_ctx.i18n_redirect
      }
    end

    # Calls default view of visual child.
    def view
      @_visual_child.view
    end

    # Adds child controller language to its context.
    def process_child_context(ctx, route)
      ctx = ctx.child
      ctx.language = route.to_sym
      ctx
    end

  end # I18n

end # Tanuki
