class Tanuki::Page::Missing < Tanuki::Controller
  def visual_parent
    nil
  end

  def result_type
    :not_found
  end
end
