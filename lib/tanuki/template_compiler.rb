module Tanuki

  # Tanuki::TemplateCompiler is used for, well, compiling templates.
  #
  # Tanuki templates are text (or HTML) files with an extended tag syntax.
  # ERB syntax is forward compatible with Tanuki template syntax.
  #
  # The following tags are recognized:
  #
  #   <% Ruby code -- output to stdout %>
  #   <%~ Ruby code -- output to stdout %>
  #   <%= Ruby expression -- replace with result %>
  #   <%# comment -- ignored -- useful in testing %>
  #   <%% or %%> -- replace with <% or %> respectively
  #   <%! Ruby expression -- must return a template %> -- renders a template
  #   <%_visitor Ruby code %> -- see Tanuki::Application::visitor for details
  #   <l10n><en>English text</en> ... -- other localizations </l10n>
  #
  # All of these tags, except +l10n+, have a single line syntax:
  #
  #   % a line of Ruby code -- treated as <% line -%>
  #   %~ a line of Ruby code -- treated as <% line -%>
  #   %= Ruby expression -- treated as <%= line -%>
  #   %# comment -- ignored -- treated as <%# line -%>
  #   %% -- replace with % if first thing on a line
  #   %! Ruby expression that returns a template -- treated as <%! line -%>
  #   %_visitor Ruby code -- treated as <%_visitor line -%>
  class TemplateCompiler

    class << self

      # Compiles a template from a given +src+ string to +ios+
      # for method +sym+ in class +klass+.
      # If +development+ is false, then no encoding and class declarations,
      # as well as runtime template checks are generated.
      # If +timer+ is true, every template render time will be measured and
      # printed to stdout.
      def compile_template(ios, src, klass, sym, development=true, timer=true)
        ios << TEMPLATE_HEADERS[:class] % [src.encoding, klass] if development
        ios << TEMPLATE_HEADERS[:method] % sym
        ios << TEMPLATE_HEADERS[:dev] % sym if development
        ios << TEMPLATE_HEADERS[:timer] if timer
        ios << TEMPLATE_HEADERS[:context] % [klass, sym]
        compile(ios, parse_wiki(src.chomp), true)
        ios << TEMPLATE_FOOTERS[:timer] % [klass, sym] if timer
        ios << TEMPLATE_FOOTERS[:dev] % sym if development
        ios << TEMPLATE_FOOTERS[:method]
        ios << TEMPLATE_FOOTERS[:class] if development
      end

      # Replaces all wiki inserts like
      # +[[controller?attribute:link#template]]+
      # with corresponding code in template tags +<%! %>+.
      def parse_wiki(s)
        s.gsub WIKI_SYNTAX do
          code = '<%! self'

          # Controller
          code << $~[:controller].split('/').map {|route|
            case route
            when '' then '.root'
            when '.' then ''
            when '..' then '.logical_parent'
            else "[:#{route}]"
            end
          }.join

          if $~[:model]
            attrs = $~[:model].split('.').map {|attr| "[:#{attr}]"}.join
            code << ".model#{attrs}"
          end
          code << ".link_to(:#{$~[:link]})" if $~[:link]

          # Template
          code << case $~[:template]
          when '' then '.view'
          when nil then '.link_view'
          else ".#{$~[:template]}_view"
          end

          code << ' %>'
        end
      end

      # Compiles code from a given +src+ string to +ios+.
      def compile(ios, src, ensure_output=false)
        state = :outer
        last_state = nil
        index = 0
        trim_newline = false
        code_buf = ''
        begin

          # Find out state for expected pattern
          pattern = expect_pattern(state)
          if new_index = src[index..-1].index(pattern)
            new_index += index
            match = src[index..-1].match(pattern)[0]
            new_state = next_state(state, match)
          else
            new_state = nil
          end

          # Process outer state (e.g. HTML or plain text)
          if state == :outer
            s = new_index ? src[index, new_index - index] : src[index..-1]
            if trim_newline && !s.empty?
              s[0] = '' if s[0] == "\n"
              trim_newline = false
            end
            if new_state == :code_skip
              code_buf << s.dup << match[0..-2]
              index = new_index + match.length
              next
            elsif not s.empty?
              ios << "\n_.(#{(code_buf << s).inspect},ctx)"
              code_buf = ''
            end
          end

          # Process current state, if there should be a state change
          if new_index
            unless state != :outer && new_state == :code_skip
              if new_state == :outer
                code_buf << src[index...new_index]
                process_code_state(ios, code_buf, state)
                code_buf = ''
              end
              index = new_index + match.length
              trim_newline = true if (match == '-%>')
              last_state = state unless state == :code_comment
              state = new_state
            else
              code_buf << src[index...new_index] << '%>'
              index = new_index + match.length
            end
          end

        end until new_index.nil?

        if ensure_output && !(PRINT_STATES.include? last_state)
          ios << "\n_.('',ctx)"
        end
        last_state
      end

      private

      # Scanner states that output the evaluated result.
      PRINT_STATES = [:outer, :code_print].freeze

      # Template header code. Sent to output before compilation.
      TEMPLATE_HEADERS = {
        :class => "# encoding: %s\nclass %s\n",
        :method => "def %s_view(args={},&block)\nproc do|_,ctx|\n",
        :dev => "if _has_tpl ctx,self.class,:%s\n",
        :timer => "_t=Time.new\n",
        :context => %{ctx=_ctx(ctx,"%s#%s")}
      }.freeze

      # Template footer code. Sent to output after compilation.
      TEMPLATE_FOOTERS = {
        :timer => %{\nputs "%s#%s - \#{'%%.4f'%%(Time.new-_t)}"},
        :dev => "\nelse\n(_run_tpl ctx,self,:%s,args,&block).(_,ctx)\nend\n",
        :method => "end\nend\n",
        :class => "end\n"
      }.freeze

      # Wiki insert syntax
      WIKI_SYNTAX = %r{
        \[\[
          (?<controller>(?:\.{1,2}(?:/\.\.)*|[a-z%0-9_]+|)(?:/[a-z%0-9_]+)*)
          (?:\?(?<model>[a-z_\.]*))?
          (?::(?<link>[a-z_]+))?
          (?:\#(?<template>[a-z_]*))?
        \]\]
      }x.freeze

      # Generates code for Ruby template bits from a given +src+ to +ios+
      # for a given +state+.
      def process_code_state(ios, src, state)
        src.strip!
        src.gsub!(/^[ \t]+/, '')
        case state
        when /code_(?:line_)?span/ then
          ios << "\n#{src}"
        when /code_(?:line_)?print/ then
          ios << "\n_.((#{src}),ctx)"
        when /code_(?:line_)?template/ then
          if src =~ /\A(.*)(do|{)\s*(\|[^\|]+\|\s*)?\Z/
            ios << "\n(#{$~[1]}{#{$~[3]}"
            @curly_end = $~[2] == '{'
          elsif !@curly_end && (src =~ /\A\s*end\s*\Z/)
            ios << '}).(_,ctx)'
          elsif @curly_end && (src =~ /\A\s*\}\s*\Z/)
            ios << '}).(_,ctx)'
          else
            ios << "\n(#{src}).(_,ctx)"
          end
        when /code_(?:line_)?visitor/
          m = src.match(/^([^ \(]+)?(\([^\)]*\))?\s*(.*)$/)
          ios << "\n#{m[1]}_result=(#{m[3]}).(#{m[1]}_visitor#{m[2]},ctx)"
        when :l10n then
          localize(ios, src)
        end
      end

      # Returns the next expected pattern for a given +state+.
      def expect_pattern(state)
        case state
        when :outer then %r{(?:^\s*|<)%[~=!_#%]?|<l10n>}
        when /\Acode_line/ then %r{\n|\Z}
        when /\Acode_(?:span|print|template|visitor|comment)/ then %r{[-%]?%>}
        when :l10n then %r{<\/l10n>}
        end
      end

      # Returns the next state for a given +match+ and a given +state+.
      def next_state(state, match)
        case state
        when :outer then
          case match
          when '<%' then :code_span
          when '<%=' then :code_print
          when '<%!' then :code_template
          when '<%_' then :code_visitor
          when '<%#' then :code_comment
          when '<%%' then :code_skip
          when '<l10n>' then :l10n
          when /\A\s*%~?\Z/ then :code_line_span
          when /\A\s*%=\Z/ then :code_line_print
          when /\A\s*%!\Z/ then :code_line_template
          when /\A\s*%_\Z/ then :code_line_visitor
          when /\A\s*%#\Z/ then :code_line_comment
          when /\A\s*%%\Z/ then :code_skip
          end
        when /\Acode_line/ then :outer
        when /\Acode_(?:span|print|template|visitor|comment)/ then
          case match
          when '%%>' then :code_skip
          else :outer
          end
        when :l10n then :outer
        end
      end

      # Generates localization code from +src+ to +ios+.
      def localize(ios, src)
        index = 0
        lngs = []
        ios << "\ncase ctx.best_language "
        code = StringIO.new
        while index = src.index(/<[a-z]{2}>/, index)
          lngs << (lng = src[index + 1, 2].to_sym)
          if end_index = src.index(/<\/#{lng}>/, index += 4)
            code << "\nwhen #{lng.inspect} then"
            compile(code, src[index...end_index])
            index = end_index + 5
          end
        end
        ios << "#{lngs.inspect.gsub(/ /, '')}#{code.string}\nend"
      end

    end # class << self

  end # TemplateCompiler

end # Tanuki
