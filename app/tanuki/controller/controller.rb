class Tanuki_Controller < Tanuki_Object
  include Enumerable

  attr_reader :model, :route, :result, :result_type, :logical_parent
  attr_accessor :logical_child, :visual_child

  def initialize(ctx, model, logical_parent=nil, route_parts=nil, index=nil)
    @ctx = process_context(ctx)
    @model = model
    @route = ''
    @logical_parent = logical_parent
    @visual_child = nil
    @active = (route_parts != nil)
    @parts = {}
    @visible_parts_count = 0
    @configured = false
    if @active
      @current = (index == route_parts.count)
      logical_parent.logical_child = self if logical_parent
      if index > 0
        @route = route_parts[index - 1][:route]
        process_args(route_parts[index - 1][:args])
      end
      if @current
        if route = default_route
          @result = combine_path(route_parts[0..index].dup << [route])
          @result_type = :redirect
        else
          @result = self
          @result_type = :page
        end
      else
        ensure_configured
        next_route = route_parts[index][:route]
        if @parts.include? next_route
          next_part = @parts[next_route]
          @logical_child = next_part[:instance] = next_part[:class].new(@ctx, next_part[:model], self, route_parts, index + 1)
          @result = @logical_child.result
          @result_type = @logical_child.result_type
        else
          @result = self
          @result_type = :not_found
        end
      end
      if @result == self
        prev = self
        while curr = prev.visual_parent
          curr.visual_child = self
          prev = curr
        end
      end
    else
      @current = false
    end
  end

  def _ctx(ctx)
    @ctx
  end

  def is_active?
    @active
  end

  def is_current?
    @current
  end

  def process_context(ctx)
    ctx
  end

  def configure
  end

  def visual_parent
    @logical_parent
  end

  def default_route
    nil
  end

  def method_missing(sym)
    if match = sym.to_s.match(/^(.*)_part$/)
      if part = @parts[match[1]]
        instantiate_part(part)
      else
        raise "undefined controller part `#{match[1]}' for #{self.class}"
      end
    else
      super
    end
  end

  def each
    ensure_configured
    @parts.each_pair {|route, part| yield(instantiate_part(part)) unless part[:hidden] }
    self
  end

  def count
    @visible_parts_count
  end

  def link
    '#'
  end

  private

  def has_part(klass, route, model, hidden=false)
    @parts[route] = {:class => klass, :model => model, :hidden => hidden, :instance => nil}
    @visible_parts_count += 1 unless hidden
    self
  end

  def instantiate_part(part)
    part[:instance] ||= part[:class].new(@ctx, part[:model], self)
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

  def self.combine_path(route_parts)
    path = ''
    route_parts.each do |route_part|
      path << route_part[:route]
      route_part[:args].each_pair {|name, value| path << ":#{name.gsub(/[\$:-]/, '$\1')}-#{value.gsub(/[\$:-]/, '$\1')}" }
    end
    path
  end

  def self.dispatch(ctx, klass, request_path)
    @part_arg ||= /:([^\$:-]*(?:(?:\$[\$:-])[^\$:-]*)*)-([^\$:-]*(?:(?:\$[\$:-])[^\$:-]*)*)/
    parts = request_path[1..-1].split('/').map do |s|
      match = s.match(/^([^:]+)(:.*)?/)
      route_part = {:route => match[1], :args => {}}
      if match[2] && matches = match[2].scan(@part_arg)
        matches.each {|m| route_part[:args][m[1].gsub(/\$([\$:-])/, '\1')] = m[2].gsub(/\$([\$:-])/, '\1') }
      end
      route_part
    end
    klass.new(ctx, nil, nil, parts, 0)
  end
end