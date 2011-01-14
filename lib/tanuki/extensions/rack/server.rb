module Rack
  class Server

    # Wraps around Rack::Server#options to update application configuration accordingly.
    def options_with_tanuki(*args, &block)
      rack_server = self
      rackup_options = options_without_tanuki(*args, &block)
      Tanuki::Application.instance_eval do
        rackup_options.each_pair {|k, v| @context.send :"#{k.downcase}=", v }
        @context.running_server = rack_server.server
      end
      rackup_options
    end

    alias_method_chain :options, :tanuki

  end #
end # Rack
