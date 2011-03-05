module Tanuki

  # Tanuki::BaseBehavior contains basic methods for a templatable object.
  # In is included in the base framework object class.
  module BaseBehavior

    # Shortcut to Tanuki::Loader::has_template?. Used internally by templates.
    def _has_tpl(ctx, klass, sym)
      Tanuki::Loader.has_template?(ctx.templates, klass, sym)
    end

    # Shortcut to Tanuki::Loader::run_template. Used internally by templates.
    def _run_tpl(ctx, obj, sym, *args, &block)
      Tanuki::Loader.run_template(ctx.templates, obj, sym, *args, &block)
    end

    # Returns the same context as given. Used internally by templates.
    def _ctx(ctx)
      ctx
    end

    # Allows to return template blocks. E. g. returns +foobar+ template block
    # when +foobar_view+ method is called.
    def method_missing(sym, *args, &block)
      if matches = sym.to_s.match(/^.*(?=_view$)|view$/)
        return Tanuki::Loader.run_template(
          {},
          self,
          matches[0].to_sym,
          *args,
          &block
        )
      end
      super
    end

    def method(sym)
      if !respond_to?(sym) && (m = sym.to_s.match(/^.*(?=_view$)|view$/))
        Tanuki::Loader.load_template({}, self, m[0].to_sym)
      end
      super
    end

  end # BaseBehavior

end # Tanuki
