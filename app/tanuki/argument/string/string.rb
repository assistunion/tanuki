class Tanuki_Argument_String < Tanuki_Argument
  def to_value(s)
    @value = s.to_s
  end
end