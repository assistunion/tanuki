class Tanuki_Object
  def _has_tpl(ctx, klass, sym)
    Tanuki::Application.has_template?(ctx.templates, klass, sym)
  end

  def _run_tpl(ctx, obj, sym, *args, &block)
    Tanuki::Application.run_template(ctx.templates, obj, sym, *args, &block)
  end

  def _ctx(ctx)
    ctx
  end

  def method_missing(sym, *args, &block)
    if matches = sym.to_s.match(/^(.*)_view$/)
      Tanuki::Application.run_template({}, self, matches[1].to_sym, *args, &block)
    else
      super
    end
  end
end