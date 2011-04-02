class Sequel::Model
  include Tanuki::BaseBehavior

  def self.fetcher(klass)
    Tanuki::Fetcher::Sequel.new(self.dataset, klass)
  end

  def self.set_controller_class(klass)
    @_tanuki_controller_class_sym = klass
  end

  def self.controller_class
    @_tanuki_controller_class ||= @_tanuki_controller_class_sym.to_s.constantize
  end
end
