load_config :common_application
set :development, true

# Rack middleware
use Rack::Reloader, 0
