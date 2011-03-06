module Tanuki

  # Tanuki::ControllerBehavior contains basic methods for a framework controller.
  # It is included in the base controller class.
  module ControllerBehavior

    include Enumerable

    internal_attr_reader :model, :logical_parent, :link, :ctx
    internal_attr_accessor :logical_child, :visual_child

    # Creates new controller with context +ctx+, +logical_parent+ controller, +route_part+ definitions and a +model+.
    def initialize(ctx, logical_parent, route_part, model=nil)
      @_configured = false
      @_ctx = ctx
      @_model = model
      @_args = {}
      if @_logical_parent = logical_parent

        # Register controller arguments, as declared with Tanuki::ControllerBehavior#has_arg.
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

    # Invoked with route +args+ when current route is initialized.
    def initialize_route(*args)
    end

    # Returns controller context. Used internally by templates.
    def _ctx(ctx, template_signature)
      if !ctx.resources.include? template_signature
        Loader.load_template_files(ctx, template_signature)
      end
      @_ctx
    end

    # Initializes and retrieves child controller on +route+. Searches static, dynamic, and ghost routes (in that order).
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
            end # if
          end # each

        end

        # If still not found, search ghost routes
        child = missing_route(route, *args) unless found

      end
      @_cache[key] = child # Thread safe (possible overwrite, but within consistent state)
    end

    # Returns +true+, if controller is active.
    def active?
      @_active
    end

    # Retrieves child controller class on +route+. Searches static, dynamic, and ghost routes (in that order).
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

    # Invoked when controller needs to be configured.
    def configure
    end

    # Returns +true+, if controller is current.
    def current?
      @_current
    end

    # If set, controller navigates to a given child route by default.
    # Returned object should be either +nil+ (don't navigate), or a +Hash+ with keys:
    # * +:route+ is the +Symbol+ for the route
    # * +:args+ contain route arguments +Hash+
    # * +:redirect+ makes a 302 redirect to this route, if true (optional)
    def default_route
      nil
    end

    # Calls +block+ once for each visible child controller on static or dynamic routes, passing it as a parameter.
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

    # Returns the link to the current controller, switching the active controller on the respective path level to +self+.
    def forward_link
      uri_parts = @_ctx.request.path_info.split(/(?<!\$)\//)
      link_parts = link.split(/(?<!\$)\//)
      link_parts.each_index {|i| uri_parts[i] = link_parts[i] }
      uri_parts.join('/') << ((qs = @_ctx.request.query_string).empty? ? '' : "?#{qs}")
    end

    # Returns the number of visible child controllers on static and dynamic routes.
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

    # Invoked when child controller context needs to be processed before initializing.
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

    # Returns the topmost visual container that should be rendered.
    def visual_top
      @_ctx.visual_top
    end

    # Returns Rack request object
    def request
      @_ctx.request
    end

    # Returns Rack response object
    def response
      @_ctx.response
    end

    # Returns Rack params hash
    def params
      request.params
    end

    # Sets HTTP response code.
    def status(value)
      @_ctx.response.status = value
    end

    # Redirects to the specified URL.
    def redirect(url)
      @_ctx.response.redirect(url)
      halt
    end

    # Includes JavaScript in page footer
    def javascript(file)
      if file.is_a? Symbol
        Loader.resource_owner self.class, file, '.js'
      end
      external = file =~ /^https?:/
      ctx.javascripts[file] = external
    end

    # Immediately stops request and returns response.
    def halt
      throw :halt
    end

    # Returns default result for HTTP GET to controller's address.
    def get
      visual_top.method(:page_view)
    end

    # Returns default result for HTTP POST to controller's address.
    def post
      status 404
      nil
    end

    # Returns default result for HTTP PUT to controller's address.
    def put
      status 404
      nil
    end

    # Returns default result for HTTP DELETE to controller's address.
    def delete
      status 404
      nil
    end

    private

    # Defines a child of class +klass+ on +route+ with +model+, optionally +hidden+.
    def has_child(klass, route, model=nil, hidden=false)
      @_child_defs[route.to_sym] = {:class => klass, :model => model, :hidden => hidden}
      @_length += 1 unless hidden
      self
    end

    # Defines a child collection of type +parse_regexp+, formatted back by +format_string+.
    def has_child_collection(parse_regexp, format_string, child_def_fetcher)
      @_child_defs[parse_regexp] = @_child_collection_defs.size
      @_child_collection_defs << {:parse => parse_regexp, :format => format_string, :fetcher => child_def_fetcher}
      @_length_is_valid = false
    end

    # Invoked for +route+ with +args+ when a route is missing. This hook can be used to make ghost routes.
    def missing_route(route, *args)
      @_ctx.missing_page.new(@_ctx, self, {:route => route, :args => []})
    end

    # Tanuki::ControllerBehavior mixed-in class methods.
    module ClassMethods

      # Returns own or superclass argument definitions.
      def arg_defs
        @_arg_defs ||= superclass.arg_defs.dup
      end

      # Escapes characters +chrs+ and encodes a given string +s+ for use in links.
      def escape(s, chrs)
        s ? Rack::Utils.escape(s.to_s.gsub(/[\$#{chrs}]/, '$\0')) : nil
      end

      # Extracts arguments, initializing default values beforehand. Searches +md+ hash for default value overrides.
      def extract_args(md)
        res = []
        arg_defs.each_pair do |name, arg|
          res[arg[:index]] = md[name]
        end
        res
      end

      # Builds link from controller +ctrl+ to a given route.
      def grow_link(ctrl, route_part, arg_defs)
        own_link = escape(route_part[:route], '\/:') << route_part[:args].map do |k, v|
          arg_defs[k][:arg].default == v ? '' : ":#{escape(k, '\/:-')}-#{escape(v, '\/:')}"
        end.join
        "#{ctrl.link == '/' ? '' : ctrl.link}/#{own_link}"
      end

      # Defines an argument with a +name+, derived from type +obj+ with additional +args+.
      def has_arg(name, obj, *args)
        # TODO Ensure thread safety
        arg_defs[name] = {:arg => Argument.to_argument(obj, *args), :index => @_arg_defs.size}
      end

      # Prepares the extended module.
      def self.extended(mod)
        mod.instance_variable_set(:@_arg_defs, {})
      end

    end # ClassMethods

    extend ClassMethods

    class << self

      # Dispathes route chain in context +ctx+ on +request_path+, starting with controller +klass+.
      def dispatch(ctx, klass, request_path)
        route_parts = parse_path(request_path)

        # Set logical children for active controllers
        curr = root_ctrl = klass.new(ctx, nil, nil, true)
        route_parts.each do |route_part|
          curr.instance_variable_set :@_active, true
          nxt = curr[route_part[:route], *route_part[:args]]
          curr.logical_child = nxt
          curr = nxt
        end

        # Set links for active controllers and default routes (only for GET)
        if ctx.request.get?
          while route_part = curr.default_route

            # Do a redirect, if some controller in the chain asks for it
            if route_part[:redirect]
              klass = curr.child_class(route_part)
              redirect grow_link(curr, route_part, klass.arg_defs)
              return
            end

            # Add default route as logical child
            curr.instance_variable_set :@_active, true
            nxt = curr[route_part[:route], *route_part[:args]]
            curr.logical_child = nxt
            curr = nxt

          end
        end

        # Find out dispatch result type from current controller
        curr.instance_variable_set :@_active, true
        curr.instance_variable_set :@_current, true
        type = (curr.is_a? ctx.missing_page) ? :missing_page : :page

        # Set visual children for active controllers
        last = curr
        prev = curr
        while curr = prev.visual_parent
          curr.visual_child = prev
          prev = curr
        end

        # Set visual top
        ctx.visual_top = prev

        last.send :"#{ctx.request.request_method.downcase}"
      end

      # Extends the including module with Tanuki::ControllerBehavior::ClassMethods.
      def included(mod)
        mod.extend ClassMethods
      end

      private

      # Parses +path+ to return route name and arguments.
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
        end # do
      end

      # Unescapes a given link part for internal use.
      def unescape(s)
        s ? s.gsub(/\$([\/\$:-])/, '\1') : nil
      end

    end # class << self

  end # ControllerBehavior

end # Tanuki
