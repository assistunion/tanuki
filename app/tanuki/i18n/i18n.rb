class Tanuki_I18n < Tanuki_Controller
  def configure
    root_page = @_ctx.root_page
    @_ctx.languages.each {|lng| has_child root_page, lng }
  end

  def default_route
    {:route => @_ctx.language.to_s, :args => {}}
  end

  def process_part_context(ctx, route)
    ctx = ctx.child
    ctx.language = route.to_sym
    ctx
  end
end