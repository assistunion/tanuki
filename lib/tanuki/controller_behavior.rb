module Tanuki

  # Tanuki::ControllerBehavior contains basic methods for a framework controller.
  # In is included in the base controller class.
  module ControllerBehavior

    include Enumerable

    internal_attr_reader :model, :logical_parent, :link
    internal_attr_accessor :logical_child, :visual_child

    # Create new controller with context ctx, logical_parent controller, route_part definitions and a model.
    def initialize(ctx, logical_parent, route_part, model=nil)
      @_configured = false
      @_ctx = ctx
      @_model = model
      @_args = {}
      if @_logical_parent = logical_parent
        @_route = route_part[:route]
        self.class.arg_defs.each_pair do |arg_name, arg_def|
          route_part[:args][arg_def[:index]] = @_args[arg_name] = arg_def[:arg].to_value(route_part[:args][arg_def[:index]])
        end
        @_link = self.class.grow_link(@_logical_parent, {:route => @_route, :args => @_args}, self.class.arg_defs)
        initialize_route(*route_part[:args])
      else
        @_link = '/'
        @_route = nil
        initialize_route
      end
    end

    # Invoked with route args when current route is initialized.
    def initialize_route(*args)
    end

    # Returns controller context. Used internally by templates.
    def _ctx(ctx)
      @_ctx
    end

    # Initializes and retrieves child route object. Searches static, dynamic, and ghost routes (in that order).
    def [](route, *args)
      byname = (args.length == 1 and args[0].is_a? Hash)
      ensure_configured!
      key = [route, args.dup]
      if cached = @_cache[key]
        # Return form cache
        return cached
      elsif child_def = @_child_defs[route]
        # Search static routes
        klass = child_def[:class]
        args = klass.extract_args(args[0]) if byname
        child = klass.new(process_child_context(@_ctx, route), self, {:route => route, :args => args}, child_def[:model])
      else
        # Search dynamic routes
        found = false
        s = route.to_s
        @_child_collection_defs.each do |collection_def|
          if md = collection_def[:parse].match(s)
            a_route = md['route'].to_sym
            child_def = collection_def[:fetcher].fetch(a_route, collection_def[:format])
            if child_def
              klass = child_def[:class]
              args = klass.extract_args(args[0]) if byname
              embedded_args = klass.extract_args(md)
              args.each_index {|i| embedded_args[i] = args[i] if args[i] }
              child = klass.new(process_child_context(@_ctx, a_route), self,
                {:route => a_route, :args => embedded_args}, child_def[:model])
              found = true
              break child
            end
          end
        end
        # If still not found, search ghost routes
        child = missing_route(route, *args) unless found
      end
      @_cache[key] = child # Thread safe (possible overwrite, but within consistent state)
    end

    # Return true, if controller is active.
    def active?
      @_active
    end

    # Retrieves child route class. Searches static, dynamic, and ghost routes (in that order).
    def child_class(route)
      ensure_configured!
      args = []
      key = [route, args]
      if cached = @_cache[key]
        # Return from cache
        return cached.class
      elsif child_def = @_child_defs[route]
        # Return from static routes
        return child_def[:class]
      else
        # Search dynamic routes
        s = route.to_s
        @_child_collection_defs.each do |collection_def|
          if md = collection_def[:parse].match(s)
            a_route = md['route'].to_sym
            child_def = collection_def[:fetcher].fetch(a_route, collection_def[:format])
            return child_def[:class] if child_def
          end
        end
        # If still not found, search ghost routes
        return (@_cache[key] = missing_route(route, *args)).class
      end
    end

    # Invoked when controller need to be configured.
    def configure
    end

    # Return true, if controller is current.
    def current?
      @_current
    end

    # If set, controller navigates to a given child route by default.
    def default_route
      nil
    end

    def each(&block)
      return Enumerator.new(self) unless block_given?
      ensure_configured!
      @_child_defs.each_pair do |route, child|
        if route.is_a? Regexp
          cd = @_child_collection_defs[child]
          cd[:fetcher].fetch_all(cd[:format]) do |child_def|
            key = [child_def[:route], []]
            unless child = @_cache[key]
              child = child_def[:class].new(process_child_context(@_ctx, route), self,
                {:route => child_def[:route], :args => {}}, child_def[:model])
              @_cache[key] = child
            end
            block.call child
          end
        else
          yield self[route] unless child[:hidden]
        end
      end
      self
    end

    # Invoked when controller configuration needs to be ensured.
    def ensure_configured!
      unless @_configured
        @_child_defs = {}
        @_child_collection_defs = []
        @_cache={}
        @_length = 0
        configure
        @_configured = true
      end
      nil
    end

    # Returns the link to the current controller, switching the active controller on the respective path level to self.
    def forward_link
      uri_parts = @_ctx.env['REQUEST_PATH'].split(/(?<!\$)\//)
      link_parts = link.split(/(?<!\$)\//)
      link_parts.each_index {|i| uri_parts[i] = link_parts[i] }
      uri_parts.join('/') << ((qs = @_ctx.env['QUERY_STRING']).empty? ? '' : "?#{qs}")
    end

    # Returns the number of children.
    def length
      if @_child_collection_defs.length > 0
        if @_length_is_valid
          @_length
        else
          @_child_collection_defs.each {|cd| @_length += cd[:fetcher].length }
          @_length_is_valid = true
        end
      else
        @_length
      end
    end

    # Kernel#method_missing hook for fetching child routes.
    def method_missing(sym, *args)
      if match = sym.to_s.match(/^(.*)_child$/)
        self[match[1].to_sym, *args]
      else
        super
      end
    end

    # Process context passed to child
    def process_child_context(ctx, route)
      ctx
    end

    alias_method :size, :length

    # Returns controller string representation. Defaults to route name.
    def to_s
      @_route.to_s
    end

    # Invoked when visual parent needs to be determined. Defaults to logical parent.
    def visual_parent
      @_logical_parent
    end

    private

    # Defines a child of class klass on route with model, optionally hidden.
    def has_child(klass, route, model=nil, hidden=false)
      @_child_defs[route] = {:class => klass, :model => model, :hidden => hidden}
      @_length += 1 unless hidden
      self
    end

    # Defines a child collection of type parse_regexp.
    def has_child_collection(parse_regexp, format_string, child_def_fetcher)
      @_child_defs[parse_regexp] = @_child_collection_defs.size
      @_child_collection_defs << {:parse => parse_regexp, :format => format_string, :fetcher => child_def_fetcher}
      @_length_is_valid = false
    end

    # Invoked for route with args when a route is missing.
    def missing_route(route, *args)
      @_ctx.missing_page.new(@_ctx, self, {:route => route, :args => []})
    end

    # Tanuki::ControllerBehavior mixed-in class methods.
    module ClassMethods

      # Returns own or superclass argument definitions.
      def arg_defs
        @_arg_defs ||= superclass.arg_defs.dup
      end

      # Escapes a given string for use in links.
      def escape(s, chrs)
        s ? Rack::Utils.escape(s.to_s.gsub(/[\$#{chrs}]/, '$\0')) : nil
      end

      # Extracts arguments, initializing default values beforehand. Searches md hash for default value overrides.
      def extract_args(md)
        res = []
        arg_defs.each_pair do |name, arg|
          res[arg[:index]] = md[name]
        end
        res
      end

      # Builds link from root to self.
      def grow_link(ctrl, route_part, arg_defs)
        own_link = escape(route_part[:route], '\/:') << route_part[:args].map do |k, v|
          arg_defs[k][:arg].default == v ? '' : ":#{escape(k, '\/:-')}-#{escape(v, '\/:')}"
        end.join
        "#{ctrl.link == '/' ? '' : ctrl.link}/#{own_link}"
      end

      # Defines an argument with name and definition arg_def.
      def has_arg(name, arg_def)
        # TODO Ensure thread safety
        arg_defs[name] = {:arg => arg_def, :index => @_arg_defs.size}
      end

      # Prepares the extended module.
      def self.extended(mod)
        mod.instance_variable_set(:@_arg_defs, {})
      end

    end # end ClassMethods

    extend ClassMethods

    class << self

      # Dispathes route chain in context ctx on request_path, starting with controller klass.
      def dispatch(ctx, klass, request_path)
        parts = parse_path(request_path)
        curr = root_ctrl = klass.new(ctx, nil, nil, true)
        parts.each do |part|
          curr.instance_variable_set :@_active, true
          nxt = curr[part[:route], *part[:args]]
          curr.logical_child = nxt
          curr = nxt
        end
        curr.instance_variable_set :@_active, true
        curr.instance_variable_set :@_current, true
        if route = curr.default_route
          klass = curr.child_class(route)
          {:type => :redirect, :location => grow_link(curr, route, klass.arg_defs)}
        else
          type = (curr.is_a? ctx.missing_page) ? :missing_page : :page
          prev = curr
          while curr = prev.visual_parent
            curr.visual_child = prev
            prev = curr
          end
          {:type => type, :controller => prev}
        end
      end

      # Extends the including module with Tanuki::ControllerBehavior::ClassMethods.
      def included(mod)
        mod.extend ClassMethods
      end

      private

      # Parses path to return route name and arguments.
      def parse_path(path)
        path[1..-1].split(/(?<!\$)\//).map do |s|
          arr = s.gsub('$/', '/').split(/(?<!\$):/)
          route_part = {:route => unescape(arr[0]).to_sym}
          args = {}
          arr[1..-1].each do |argval|
            varr = argval.split(/(?<!\$)-/)
            args[unescape(varr[0])] = unescape(varr[1..-1].join) # TODO Predict argument
          end
          route_part[:args] = extract_args(args)
          route_part
        end
      end

      # Unescape a given link part for internal use.
      def unescape(s)
        s ? s.gsub(/\$([\/\$:-])/, '\1') : nil
      end

    end # end class << self

  end # end ControllerBehavior

end # end Tanuki