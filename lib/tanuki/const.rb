module Tanuki

  # This module includes constants that are commonly used
  # during requests in the framework.
  # All of them are frozen to keep the GC from unwanted stress.
  module Const

    ARG_KEY_ESCAPE = '\/:-'.freeze
    ARG_VALUE_ESCAPE = '\/:'.freeze
    CONTENT_TYPE = 'Content-Type'.freeze
    EMPTY_ARRAY = [].freeze
    EMPTY_STRING = ''.freeze
    ESCAPED_MATCH = '$\0'.freeze
    ESCAPED_ROUTE_CHARS = /\$([\/\$:-])/.freeze
    ESCAPED_SLASH = '$/'.freeze
    ETAG = 'ETag'.freeze
    FIRST_SUBPATTERN = '\1'.freeze
    LOCATION = 'Location'.freeze
    MIME_TEXT_HTML = 'text/html; charset=utf-8'.freeze
    PATH_INFO = 'PATH_INFO'.freeze
    QUERY_STRING = 'QUERY_STRING'.freeze
    SLASH = '/'.freeze
    TRAILING_SLASH = /^(.+)(?<!\$)\/$/.freeze
    UNESCAPED_COLON = /(?<!\$):/.freeze
    UNESCAPED_MINUS = /(?<!\$)-/.freeze
    UNESCAPED_SLASH = /(?<!\$)\//.freeze
    UTF_8 = 'UTF-8'.freeze
    VIEW_METHOD = /^.*_view$/.freeze

  end # Const

end # Tanuki
