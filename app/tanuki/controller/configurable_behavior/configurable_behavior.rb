module Tanuki::Controller::ConfigurableBehavior
  def configure
    model[:children].each_pair do |route, child|
      has_child child[:controller], route, child, child[:hidden]
    end
  end

  def default_route
    first_route if model[:autoselect_first]
  end

  def to_s
    model[:title]
  end
end
