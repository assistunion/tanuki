class Tanuki_Attribute
  def initialize(cfg, owner)
    #--
    # created on demand (first access)
    # cfg is a parsed yaml hash
    # attribute owner object
    # all Object and Collection attrs are defined in relations
    @cfg = cfg
    @owner = owner
  end

  def required?
    @cfg[:required]
  end

  def value
    # value of data (scalar, array, or hash)
  end
end