class Tanuki_Argument
  attr_accessor :value
  attr_reader :default

  def initialize(default)
    @value = @default = default
  end

  def set(s)
    @value = to_value(s)
    self
  end
end