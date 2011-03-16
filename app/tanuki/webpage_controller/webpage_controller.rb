class Tanuki::WebpageController < Tanuki::Controller
  def configure
    fetcher = nil
    if (self.model && self.model.key?(:children))
      fetcher = Tanuki::Fetcher::WebpageFetcher.new(self.model)
    else
      fetcher = Tanuki::Fetcher::WebpageFetcher.new
    end
    has_child_collection(fetcher, /.*/)
  end


  def default_route
    page = self.model[:webpage]
    if page['autoselect_first']
      if defined?(page['children']) && page['children'].count > 0
        {
          :route => page['children'].first[0],
          :args => {},
          :redirect => true
        }
      else
        return nil unless route_found
      end

    end
  end

  def to_s
    self.model[:webpage]['title']
  end
end