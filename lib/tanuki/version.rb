module Tanuki

  # Tanuki framework version as an Array.
  VERSION = [0, 4, 0].freeze

  # Returns Tanuki framework version as a dotted string.
  def self.version
    VERSION.join '.'
  end

end # Tanuki
