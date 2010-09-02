module Rack
  class StaticDir

    # Initializes a Rack::File server at +root+ or +Dir.pwd+.
    def initialize(app, root=nil)
      @app = app
      @file_server = Rack::File.new(root || Dir.pwd)
    end

    # Returns file contents, if requested file exists.
    def call(env)
      result = @file_server.call(env)
      return result if result[0] == 200
      @app.call(env)
    end

  end # end
end # end Rack