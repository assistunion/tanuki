class Tanuki::Fetcher::Sequel
  def initialize(dataset, controller_class)
    @dataset = dataset
    @controller_class = controller_class
  end

  def fetch(md, format)
    table = @dataset.first_source_alias
    keys = Hash[md.names.map {|name| ["#{table}__#{name}".to_sym, md[name]] }]
    item = @dataset.filter(keys).first
    if item
      {
        :class => @controller_class,
        :model => item,
        :route => format.call(item).to_sym
      }
    else
      nil
    end
  end

  def fetch_all(format)
    @items ||= @dataset.all
    @items.each do |item|
      yield({
        :class => @controller_class,
        :model => item,
        :route => format.call(item).to_sym
      })
    end
  end

  def length
    @dataset.count
  end
end
