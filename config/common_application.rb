load_config :common

# Rack middleware
use Rack::Head
use Rack::StaticDir, @context.public_root

# Environment
set :development, false

# Default controllers
set :root_page, ::User::Page::Home
set :missing_page, ::Tanuki::Page::Missing

# Internationalization
set :i18n, false
set :i18n_redirect, false
set :language, nil
set :language_fallback, {}
set :languages, proc { language_fallback.keys }
set :best_language, proc {|lngs| language_fallback[language].each {|lng| return lng if lngs.include? lng }; nil }
set :best_translation, proc {|trn| language_fallback[language].each {|lng| return trn[lng] if trn.include? lng }; nil }

# Visitors
visitor :string do s = ''; proc {|out| s << out.to_s } end

# Argument associations
argument Fixnum, Argument::Integer
argument Bignum, Argument::Integer
argument Range, Argument::IntegerRange
argument String, Argument::String
