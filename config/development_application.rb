load_config :common_application
set :development, true
set :timers, true

# Rack middleware
use Rack::Reloader, 0
