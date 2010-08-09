class Tanuki_Controller < Tanuki_Object
  include Enumerable

  attr_reader :model, :result, :result_type, :logical_parent, :link
  attr_accessor :logical_child, :visual_child

  def initialize(ctx, logical_parent, route_part, model=nil)
    @configured = false
    @ctx = ctx
    @model = model
    @args = {}
    if @logical_parent = logical_parent
      @route = route_part[:route]
      self.class.arg_defs.each_pair do |arg_name, arg_def|
        route_part[:args][arg_def[:index]] = @args[arg_name] = arg_def[:arg].to_value(route_part[:args][arg_def[:index]])
      end
      @link = self.class.grow_link(@logical_parent, {:route => @route, :args => @args}, self.class.arg_defs)
      initialize_route(*route_part[:args])
    else
      @link = '/'
      @route = nil
      initialize_route
    end
  end

  def initialize_route(*)
  end


  def _ctx(ctx)
    @ctx
  end

  def active?
    @active
  end

  def active=(v)
    @active = v
  end

  def configure
  end

  def current?
    @current
  end

  def current=(v)
    @current = v
  end

  def default_route
    nil
  end

  def each
    # TODO
    ensure_configured!
    @child_defs.each_pair {|route, child| yield self[route] unless child[:hidden] }
    self
  end

  def forward_link
    uri_parts = @ctx.env['REQUEST_PATH'].split(/(?<!\$)\//)
    link_parts = link.split(/(?<!\$)\//)
    link_parts.each_index {|i| uri_parts[i] = link_parts[i] }
    uri_parts.join('/') << ((qs = @ctx.env['QUERY_STRING']).empty? ? '' : "?#{qs}")
  end

  def method_missing(sym, *args)
    if match = sym.to_s.match(/^(.*)_part$/)
      self[match[1].to_sym, *args]
    else
      super
    end
  end

  # Process context passed to child
  def prepare_child_context(ctx, route)
    ctx
  end

  def to_s
    @route
  end

  def visual_parent
    @logical_parent
  end

  def ensure_configured!
    unless @configured
      @child_defs = {}
      @child_collection_defs = []
      @cache={}
      @length = 0
      configure
      @configured = true
    end
    nil
  end

  def child_class(route)
    ensure_configured!
    args = []
    key = [route, args]
    if cached = @cache[key] # search cache
      return cached.class
    elsif child_def = @child_defs[route] # search static routes
      return child_def[:class]
    else
      s = route.to_s
      @child_collection_defs.each do |collection_def|
        if md = collection_def[:parse].match(s)
          a_route = md['route'].to_sym
          child_def = collection_def[:fetcher].get(a_route)
          if child_def
            return child_def[:class]
          end
        end
      end
      return (@cache[key] = missing_route(route, *args)).class  # search ghost routes
    end
  end

  def [](route, *args)
    byname = (args.length == 1 and args[0].is_a? Hash)
    ensure_configured!
    key = [route, args.dup]
    if cached = @cache[key] # search cache
      return cached
    elsif child_def = @child_defs[route] # search static routes
      klass = child_def[:class]
      args = klass.extract_args(args[0]) if byname
      child = klass.new(@ctx, self, { :route=>route, :args=>args }, child_def[:model])
    else
      found = false # search dynamic routes
      s = route.to_s
      @child_collection_defs.each do |collection_def|
        if md = collection_def[:parse].match(s)
          a_route = md['route'].to_sym
          child_def = collection_def[:fetcher].get(a_route)
          if child_def
            klass = child_def[:class]
            args = klass.extract_args(args[0]) if byname
            embedded_args = klass.extract_args(md)
            args.each_index do |i|
              embedded_args[i] = args[i] if args[i]
            end
            child = klass.new(@ctx, self, {:route=>a_route, :args=>embedded_args}, child_def[:model])
            found = true
            break child
          end
        end
      end
      child = missing_route(route, *args) unless found   # search ghost routes
    end
    @cache[key] = child # thread safe (possible overwrite, but within consistent state)
  end

  def length
    if @child_collection_defs.length > 0
      if @length_is_valid
        @length
      else
        @child_collection_defs.each {|cd| @length += cd[:fetcher].length }
        @length_is_valid = true
      end
    else
      @length
    end
  end

  alias_method :size, :length

  private

  def has_child(klass, route, model=nil, hidden=false)
    @child_defs[route] = {:class => klass, :model => model, :hidden => hidden}
    @length += 1 unless hidden
    self
  end

  def has_child_collection(parse_regexp, format_string, child_def_fetcher)
    @child_defs[parse_regexp] = @child_collection_defs.size
    @child_collection_defs << {:parse => parse_regexp, :format => format_string, :fetcher => child_def_fetcher}
    @length_is_valid = false
  end

  def missing_route(route, *args)
    Tanuki_Missing.new(@ctx, self, {:route => route, :args => []})
  end

  @arg_defs = {}

  class << self

    def escape(s, chrs)
      s ? Rack::Utils.escape(s.to_s.gsub(/[\$#{chrs}]/, '$\0')) : nil
    end

    def grow_link(ctrl, route_part, arg_defs)
      own_link = escape(route_part[:route], '\/:') << route_part[:args].map do |k, v|
        arg_defs[k][:arg].default == v ? '' : ":#{escape(k, '\/:-')}-#{escape(v, '\/:')}"
      end.join
      "#{ctrl.link == '/' ? '' : ctrl.link}/#{own_link}"
    end


    def dispatch(ctx, klass, request_path)
      parts = parse_path(request_path)
      curr = root_ctrl = klass.new(ctx, nil, nil, true)
      parts.each do |part|
        curr.active = true
        nxt = curr[part[:route], *part[:args]]
        curr.logical_child = nxt
        curr = nxt
      end
      curr.instance_variable_set :@active, true
      curr.instance_variable_set :@current, true
      if route = curr.default_route
        klass = curr.child_class(route)
        {:type => :redirect, :location => grow_link(curr, route, klass.arg_defs)}
      else
        prev = curr
        while curr = prev.visual_parent
          curr.visual_child = prev
          prev = curr
        end
        {:type => :page, :controller => prev}
      end
    end

    def arg_defs
      @arg_defs ||= superclass.arg_defs.dup
    end

    def has_arg (name, arg_def)
      # TODO Ensure thread safety
      arg_defs[name] = {:arg => arg_def, :index => @arg_defs.size}
    end

    def extract_args(md)
      res = []
      arg_defs.each_pair do |name,arg|
        res[arg[:index]] = md[name]
      end
      res
    end

    private

    def parse_path(path)
      path[1..-1].split(/(?<!\$)\//).map do |s|
        arr = s.gsub('$/', '/').split(/(?<!\$):/)
        route_part = {:route => unescape(arr[0]).to_sym}
        args = {}
        arr[1..-1].each do |argval|
          varr = argval.split(/(?<!\$)-/)
          args[unescape(varr[0])] = unescape(varr[1..-1].join)
        end
        route_part[:args] = extract_args(args)
        route_part
      end
    end

    def unescape(s)
      s ? s.gsub(/\$([\/\$:-])/, '\1') : nil
    end
  end
end

# class Tanuki_Manager < Tanuki_Controller
#   has_arg :mode Tanuki_Argument_List(['a','b','c'],'a')
#   has_arg :page Tanuki_Argument_Integer(1)
#   has_arg :per_page Tanuki_Argument_Integer(25)

#   def configure
#   end
# end








