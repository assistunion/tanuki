module Tanuki
  class TemplateCompiler
    def self.compile(ios, src, klass = nil, sym = nil)
      state = :outer
      last_state = nil
      index = 0
      trim_newline = false
      ios << "# encoding: utf-8\nclass #{klass}\ndef #{sym}_view(*args,&block)\nproc do|_,ctx|\n" \
        "if _has_tpl ctx,self.class,:#{sym}\nctx=_ctx(ctx)" if klass && sym
      begin
        if new_index = src.index(expect_pattern(state), index)
          match = src[index..-1].match(expect_pattern(state))[0]
          new_state = next_state(state, match)
        else
          new_state = nil
        end
        skip = new_state == :code_skip
        if state == :outer || skip
          if new_index
            s = src[index, new_index - index]
            if trim_newline
              s[0] = '' if s[0] == "\n"
              trim_newline = false
            end
          else
            s = src[index..-1]
          end
          unless s.empty?
            if skip
              ios << "\n_.call(#{(s << '<%').inspect},ctx)" unless s.empty?
              index = new_index + 3
              next
            else
              ios << "\n_.call(#{s.inspect},ctx)" unless s.empty?
            end
          end
        end
        if new_index
          if new_state == :outer
            case state
            when :code_line, :code_span then
              ios << "\n#{src[index...new_index].strip}"
            when :code_print then
              ios << "\n_.call((#{src[index...new_index].strip}),ctx)"
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
        ios << "\nelse\n(_run_tpl ctx,self,:#{sym},*args,&block).call(_,ctx)\nend\nend\nend\nend"
      end
    end

    private

    PRINT_STATES = [:outer, :code_print]
    TRIM_STATES = [:code_span, :code_print, :code_template, :code_comment]

    def self.expect_pattern(state)
      case state
      when :outer then %r{(?:^(?=\s*)%|<%(?:=|\!|#|%|))|<l10n>}
      when :code_line then %r{\n|\Z}
      when :code_span, :code_print, :code_template, :code_comment then %r{-?%>}
      when :l10n then %r{<\/l10n>}
      end
    end

    def self.next_state(state, match)
      case state
      when :outer then
        case match
        when '%' then :code_line
        when '<%' then :code_span
        when '<%=' then :code_print
        when '<%!' then :code_template
        when '<%#' then :code_comment
        when '<%%' then :code_skip
        when '<l10n>' then :l10n
        end
      when :code_line then :outer
      when :code_span, :code_print, :code_template, :code_comment then :outer
      when :l10n then :outer
      end
    end

    def self.localize(ios, src)
      index = 0
      lngs = []
      ios << "\ncase ctx.best_language "
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
