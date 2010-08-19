class Tanuki_Model
  @attributes = {}
  @relations = {}

  def initialize(data)
    @data = data
  end

  def self.attribute(attr)
    # add to @attributes
  end

  def self.relation(rel)
    # add to @relations
  end

  def method_mising(sym)
    # creates Tanuki_Attribute
  end
end