class Tanuki_MetaModel

  def initialize(namespace, name, data)
    @namespace = namespace
    @name = name
    @data = data
  end

  def class_name_for(class_type)
    case class_type
    when :model then "#{@namespace}_Model_#{@name}"
    when :model_base then "#{@namespace}_Model_#{@name}_Base"
    when :manager then "#{@namespace}_Manager_#{@name}"
    when :manager_base then "#{@namespace}_Manager_#{@name}_Base"
    end
  end

end