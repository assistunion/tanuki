module Tanuki_Object
  def _has_tpl(klass, sym)
    Tanuki::Application.has_template?(klass, sym)
  end

  def _run_tpl(obj, sym, *args, &block)
    Tanuki::Application.run_template(obj, sym, *args, &block)
  end

  def _lngs(lngs)
    Tanuki::Localization.current.available(lngs)
  end

  def method_missing(sym, *args, &block)
    if matches = sym.to_s.match(/^(.*)_view$/)
      Tanuki::Application.run_template(self, matches[1].to_sym, *args, &block)
    else
      super
    end
  end
end