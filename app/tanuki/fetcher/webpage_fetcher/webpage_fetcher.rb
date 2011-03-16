class Tanuki::Fetcher::WebpageFetcher
  DEFAULT_VALUES = {
    :controller => 'User::Page::Autoconfigured',
    :title => 'Webpage',
    :autoselect_first => false,
    :children => {}
  }

  def initialize(pages = nil)
    @model = {}
    if pages
      @model[:tree] = pages[:tree]
      @model[:children] = pages[:children]
    else
      @model[:tree] = load_page_config('config/webpages.yml')
      @model[:children] = nil
    end
  end

  def load_page_config(file)
    tree = YAML.load_file(file)
    tree.each_value{|v|
       merge_with_defaults(v)
    }
    tree
  end

  def merge_with_defaults(tree)
    DEFAULT_VALUES.each{|k, v|
      tree[k.to_s] = v unless tree.key?(k.to_s)
    }

    tree['children'].each_value{|v|
       merge_with_defaults(v)
    }
  end

  def fetch(md, format)
    root = @model[:tree]
    root = @model[:children] if @model[:children]

    route_found = false
    root.each_pair {|route, webpage|
      if route == md.to_s
        route_found = true
        @model[:children] = webpage['children'] if (webpage.key?('children'))
        @model[:webpage] = webpage
      end
    }

    return nil unless route_found
    page = @model[:webpage]
    if page['autoselect_first']
      return nil unless page['children'] && page['children'].count > 0
    end

    {
      :class => @model[:webpage]['controller'].constantize,
      :model => @model,
      :route => md.to_s.to_sym
    }

  end

  def fetch_all(format)
    root = @model[:tree]
    root = @model[:children] if @model[:children]

    root.each_pair {|route, webpage|
      model = @model.clone
      model[:children] = webpage['children']
      model[:webpage] = webpage
      yield ({
        :class => webpage['controller'].constantize,
        :model => model,
        :route => route.to_sym
      })
    }
  end
end
