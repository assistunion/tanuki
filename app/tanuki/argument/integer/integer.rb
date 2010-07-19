class Tanuki_Argument_Integer < Tanuki_Argument
  def to_value(s)
    @value = begin Integer s rescue @default end
  end
end