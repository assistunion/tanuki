class Sequel::Model
  include Tanuki::BaseBehavior

  def self.fetcher(controller_class)
    @_tanuki_fetcher ||= Tanuki::Fetcher::Sequel.new(self, controller_class)
  end
end
