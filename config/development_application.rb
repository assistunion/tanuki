load_config :common_application
set :development, true

# Rack middleware
use Rack::CommonLogger
use Rack::Lint
use Rack::Reloader, 0
use Rack::ShowExceptions
