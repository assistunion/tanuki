module Rack
  class Server

    alias_method :orig_options, :options

    # Overrides Rack::Server#options to update application configuration accordingly.
    #--
    # TODO This will surely break in future versions of Rack. :(
    def options(*args, &block)
      rack_server = self
      rackup_options = orig_options(*args, &block)
      Tanuki::Application.instance_eval do
        # TODO Should we really convert :Port to :port, etc? What about @context[:entry]?
        rackup_options.each_pair {|k, v| @context.send :"#{k.downcase}=", v }
        @context.running_server = rack_server.server
      end
      rackup_options
    end

  end # end
end # end Rack