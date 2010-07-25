module Tanuki
  class TemplateCompiler
    EXPECT = {
      :outer => /(?:^(?=\s*)%|<%(?:=|&|#|%|))|<l10n>/,
      :code_line => /\n/,
      :code_span => /-?%>/,
      :code_print => /-?%>/,
      :code_template => /-?%>/,
      :code_comment => /-?%>/,
      :l10n => /<\/l10n>/
    }
    STATES = {
      :outer => {
        '%' => :code_line,
        '<%' => :code_span,
        '<%=' => :code_print,
        '<%&' => :code_template,
        '<%#' => :code_comment,
        '<%%' => :code_skip,
        '<l10n>' => :l10n
      },
      :code_line => {
        "\n" => :outer
      },
      :code_span => {
        '%>' => :outer,
        '-%>' => :outer
      },
      :code_print => {
        '%>' => :outer,
        '-%>' => :outer
      },
      :code_template => {
        '%>' => :outer,
        '-%>' => :outer
      },
      :code_comment => {
        '%>' => :outer,
        '-%>' => :outer
      },
      :l10n => {
        '</l10n>' => :outer
      }
    }

    PRINT_STATES = [:outer, :code_print]
    TRIM_STATES = [:code_span, :code_print, :code_template, :code_comment]

    def self.compile(ios, src, klass = nil, sym = nil)
      state = :outer
      last_state = nil
      index = 0
      trim_newline = false
      ios << "# encoding: utf-8\nclass #{klass}\ndef #{sym}_view(*args,&block)\n" \
        "_run_tpl self,:#{sym},*args,&block unless _has_tpl self.class,:#{sym}\n" \
        "proc do|_,ctx|\nctx=_ctx(ctx)" if klass && sym
      begin
        if new_index = src.index(EXPECT[state], index)
          match = src[index..-1].match(EXPECT[state])[0]
          new_state = STATES[state][match]
        else
          new_state = nil
        end
        skip = new_state == :code_skip
        if state == :outer || skip
          s = src[index..(new_index ? new_index - 1 : -1)]
          if trim_newline
            s[0] = '' if s[0] == "\n"
            trim_newline = false
          end
          if skip
            ios << "\n_.call(#{(s << '<%').inspect},ctx)" unless s.empty?
            index = new_index + 3
            next
          else
            ios << "\n_.call(#{s.inspect},ctx)" unless s.empty?
          end
        end
        if new_index
          if new_state == :outer
            case state
            when :code_line, :code_span then
              ios << "\n#{src[index...new_index].strip}"
            when :code_print then
              ios << "\n_.call(#{src[index...new_index].strip},ctx)"
            when :code_template then
              ios << "\n(#{src[index...new_index].strip}).call(_,ctx)"
            when :l10n then
              localize(ios, src[index...new_index].strip)
            end
          end
          index = new_index + match.length
          trim_newline = true if (match == '-%>') && TRIM_STATES.include?(state)
          last_state = state unless state == :code_comment
          state = new_state
        end
      end until new_index.nil?
      if klass && sym
        ios << "\n_.call('',ctx)" unless PRINT_STATES.include? last_state
        ios << "\nend\nend\nend"
      end
    end

    def self.localize(ios, src)
      index = 0
      lngs = []
      ios << "\ncase _lngs "
      code = StringIO.new
      while index = src.index(/<[a-z]{2}>/, index)
        lngs << (lng = src[index + 1, 2].to_sym)
        if end_index = src.index(/<\/#{lng}>/, index += 4)
          code << "\nwhen #{lng.inspect} then "
          compile(code, src[index...end_index])
          index = end_index + 5
        end
      end
      ios << "#{lngs.inspect.gsub(/ /, '')}#{code.string}\nend"
    end
  end
end
