# encoding: utf-8
class Tanuki_Controller < Tanuki_Object
  include Enumerable

  attr_reader :model, :route, :result, :result_type, :logical_parent, :link
  attr_accessor :logical_child, :visual_child

  def initialize(ctx, model, logical_parent, route_parts, index, active)
    @ctx = process_context(ctx)
    @model = model
    @link = '/'
    if index > 0
      route_part = route_parts[index - 1]
      @route = route_part[:route]
      process_args(route_part[:args])
      @link = grow_link(@logical_parent, route_part) if @logical_parent = logical_parent
    else
      @route = ''
    end
    @visual_child = nil
    @parts = {}
    @visible_parts_count = 0
    @configured = false
    if @active = active
      @logical_parent.logical_child = self if @logical_parent
      if @current = (index == route_parts.count)
        if route_part = default_route
          @result = grow_link(self, route_part)
          @result_type = :redirect
        else
          @result = self
          @result_type = :page
          @result_type = result_type
        end
      else
        ensure_configured
        next_route = route_parts[index][:route]
        if @parts.include? next_route
          next_part = @parts[next_route]
          @logical_child = next_part[:instance] = next_part[:class].new(process_part_context(@ctx, next_route),
            next_part[:model], self, route_parts, index + 1, true)
          @result = @logical_child.result
          @result_type = @logical_child.result_type
        else
          @logical_child = part_missing.new(process_part_context(@ctx, @route), nil, self, route_parts, index + 1, true)
          @result = @logical_child.result
          @result_type = @logical_child.result_type
        end
      end
    else
      @current = false
    end
  end

  def _ctx(ctx)
    @ctx
  end

  def active?
    @active
  end

  def current?
    @current
  end

  def process_context(ctx)
    ctx
  end

  def process_part_context(ctx, route)
    ctx
  end

  def configure
  end

  def visual_parent
    @logical_parent
  end

  def forward_link
    uri_parts = @ctx.env['REQUEST_PATH'].split(/(?<!\$)\//)
    link_parts = link.split(/(?<!\$)\//)
    link_parts.each_index {|i| uri_parts[i] = link_parts[i] }
    uri_parts.join('/') << ((qs = @ctx.env['QUERY_STRING']).empty? ? '' : "?#{qs}")
  end

  def default_route
    nil
  end

  def part_missing
    Tanuki_Missing
  end

  def method_missing(sym)
    if match = sym.to_s.match(/^(.*)_part$/)
      if part = @parts[match[1]]
        instantiate_part(match[1], part)
      else
        raise "undefined controller part `#{match[1]}' for #{self.class}"
      end
    else
      super
    end
  end

  def to_s
    @route
  end

  def each
    ensure_configured
    @parts.each_pair {|route, part| yield(instantiate_part(route, part)) unless part[:hidden] }
    self
  end

  def count
    @visible_parts_count
  end

  private

  def has_part(klass, route, model=nil, hidden=false)
    @parts[route] = {:class => klass, :model => model, :hidden => hidden, :instance => nil}
    @visible_parts_count += 1 unless hidden
    self
  end

  def instantiate_part(route, part)
    part[:instance] ||= part[:class].new(process_part_context(@ctx, route), part[:model], self,
      [{:route => route, :args => {}}], 1, false)
  end

  def ensure_configured
    unless @configured
      configure
      @configured = true
    end
    self
  end

  def process_args(args)
    # TODO
  end

  def grow_link(ctrl, route_part)
    own_link = escape(route_part[:route], '\/:') << route_part[:args].map do |k, v|
      ":#{escape(k, '\/:-')}-#{escape(v, '\/:')}"
    end.join
    "#{ctrl.link == '/' ? '' : ctrl.link}/#{own_link}"
  end

  def escape(s, chrs)
    s ? Rack::Utils.escape(s.gsub(/[\$#{chrs}]/, '$\0')) : nil
  end

  def self.unescape(s)
    s ? s.gsub(/\$([\/\$:-])/, '\1') : nil
  end

  def self.dispatch(ctx, klass, request_path)
    parts = request_path[1..-1].split(/(?<!\$)\//).map do |s|
      arr = s.gsub('$/', '/').split(/(?<!\$):/)
      route_part = {:route => unescape(arr[0]), :args => {}}
      arr[1..-1].each do |argval|
        varr = argval.split(/(?<!\$)-/)
        route_part[:args][unescape(varr[0])] = unescape(varr[1..-1].join)
      end
      route_part
    end
    root_ctrl = klass.new(ctx, nil, nil, parts, 0, true)
    if (prev = root_ctrl.result).is_a? Tanuki_Controller
      while curr = prev.visual_parent
        curr.visual_child = prev
        prev = curr
      end
      prev
    else
      root_ctrl
    end
  end
end