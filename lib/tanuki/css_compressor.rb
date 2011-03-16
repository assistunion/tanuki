module Tanuki

  # Tanuki::CssCompressor takes a CSS source and makes it shorter,
  # trying not to break the semantics.
  class CssCompressor

    class << self

      # Compresses CSS source in +css+.
      def compress(css)
        @css = css
        compress_structure
        compress_colors
        compress_dimensions
        @css
      end

      private

      # Compresses the CSS structure in +@css+.
      def compress_structure
        @css.gsub!(%r{/\*.*\*/}, '')
        @css.strip!.gsub!(/\s*(\s|;|:|}|{|\)|\(|,)\s*/, '\1')
        @css.gsub!(/[;]+/, ';')
        @css.gsub!(';}', '}')
      end

      # Compresses CSS color values in +@css+.
      def compress_colors
        @css.gsub! /rgb\((\d{1,3}),(\d{1,3}),(\d{1,3})\)/ do
          r = $~[1].to_i.to_s(16).rjust(2, '0')
          g = $~[2].to_i.to_s(16).rjust(2, '0')
          b = $~[3].to_i.to_s(16).rjust(2, '0')
          "##{r}#{g}#{b}"
        end
        @css.gsub!(/#([0-9a-f])\1([0-9a-f])\2([0-9a-f])\3/, '#\1\2\3')
      end

      # Compresses CSS dimension values in +@css+.
      def compress_dimensions
        @css.gsub!(/(?<=[\s:])0(?:%|cm|em|ex|in|mm|pc|pt|px)/, '0')
        @css.gsub!(/(?<=[\s:])([0-9]+[a-z]*)\s+\1\s+\1\s+\1/, '\1')
        @css.gsub!(/(?<=[\s:])(\d+[a-z]*)\s+(\d+[a-z]*)\s+\1\s+\2/, '\1 \2')
      end

    end

  end # CssCompressor

end # Tanuki
