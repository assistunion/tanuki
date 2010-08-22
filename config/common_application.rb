# Rack middleware
use Rack::Head
use Rack::ShowStatus

# Server
set :server, [:thin, :mongrel, :webrick]
set :host, '0.0.0.0'
set :port, 3000

# Default controllers
set :root_page, ::User_Page_Index
set :missing_page, ::Tanuki_Page_Missing

# Internationalization
set :i18n, false
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