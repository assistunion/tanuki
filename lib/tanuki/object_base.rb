module Tanuki

  # Tanuki::ControllerBase contains basic methods for a framework object.
  # In is included in the base framework object class.
  module ObjectBase

    # Shortcut to Tanuki::Loader.has_template?. Used internally by templates.
    def _has_tpl(ctx, klass, sym)
      Tanuki::Loader.has_template?(ctx.templates, klass, sym)
    end

    # Shortcut to Tanuki::Loader.run_template. Used internally by templates.
    def _run_tpl(ctx, obj, sym, *args, &block)
      Tanuki::Loader.run_template(ctx.templates, obj, sym, *args, &block)
    end

    # Returns the same context as given. Used internally by templates.
    def _ctx(ctx)
      ctx
    end

    # Kernel#method_missing hook for fetching views.
    def method_missing(sym, *args, &block)
      if matches = sym.to_s.match(/^(.*)_view$/)
        return Tanuki::Loader.run_template({}, self, matches[1].to_sym, *args, &block)
      end
      super
    end

  end # end ObjectBase

end # end Tanuki