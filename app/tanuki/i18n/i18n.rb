class Tanuki_I18n < Tanuki_Controller
  def configure
    root_page = @ctx.root_page
    @ctx.language_fallback.keys.each {|lng| has_part root_page, lng.to_s }
  end

  def default_route
    {:route => @ctx.language.to_s, :args => {}}
  end

  def process_part_context(ctx, route)
    ctx = ctx.child
    ctx.language = route.to_sym
    ctx
  end
end