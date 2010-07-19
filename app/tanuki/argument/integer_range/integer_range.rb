class Tanuki_Argument_IntegerRange < Tanuki_Argument_Integer
  def initialize(default, range)
    super(default)
    @range = range
  end

  def to_value(s)
    i = super(s)
    @range.include?(i) ? i : @default
  end
end