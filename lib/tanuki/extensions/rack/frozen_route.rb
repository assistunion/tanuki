require 'digest'

module Rack
  class FrozenRoute

    # Creates a new +route+ (defined by a regular expression)
    # that yields the same +body+ throughout the whole life of the
    # application.
    def initialize(app, route, content_type, body)
      @app = app
      @route = route
      @headers = {
        'Content-Type' => content_type,
        'ETag'         => Digest::MD5.hexdigest(body)
      }
      @body = body
    end

    # Returns the defined +body+ if the route is matched.
    def call(env)
      if env['PATH_INFO'] =~ @route
        if @headers['ETag'] == env['HTTP_IF_NONE_MATCH']
          status = 304
          body = ''
        else
          status = 200
          body = @body
        end
        return [status, @headers, body]
      end
      @app.call(env)
    end

  end # FrozenRoute
end # Rack
