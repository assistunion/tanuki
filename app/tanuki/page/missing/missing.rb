class Tanuki::Page::Missing < Tanuki::Controller
  def visual_parent
    nil
  end

  def get # TODO: add other request methods
    status 404
    super
  end
end
