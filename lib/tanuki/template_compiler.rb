module Tanuki
  class TemplateCompiler
    EXPECT = {
      :outer => /(?:^(?=\s*)%|<%(?:=|&|#)?)|<l10n>/,
      :code_line => /\n/,
      :code_span => /%>/,
      :code_print => /%>/,
      :code_template => /%>/,
      :code_comment => /%>/,
      :l10n => /<\/l10n>/
    }
    STATES = {
      :outer => {
        '%' => :code_line,
        '<%' => :code_span,
        '<%=' => :code_print,
        '<%&' => :code_template,
        '<%#' => :code_comment,
        '<l10n>' => :l10n
      },
      :code_line => {
        "\n" => :outer
      },
      :code_span => {
        '%>' => :outer
      },
      :code_print => {
        '%>' => :outer
      },
      :code_template => {
        '%>' => :outer
      },
      :code_comment => {
        '%>' => :outer
      },
      :l10n => {
        '</l10n>' => :outer
      }
    }

    PRINT_STATES = [:outer, :code_print]

    def self.compile(ios, src, klass = nil, sym = nil)
      state = :outer
      last_state = nil
      index = 0
      ios << "class #{klass}\ndef #{sym}_view(*args,&block)\n"\
        << "_run_tpl self,:#{sym},*args,&block "\
        << "unless _has_tpl self.class,:#{sym}\nproc do|_|" if klass && sym
      begin
        if new_index = src.index(EXPECT[state], index)
          match = src[index..-1].match(EXPECT[state])[0]
          new_state = STATES[state][match]
        else
          new_state = nil
        end
        if state == :outer
          s = src[index..(new_index ? new_index - 1 : -1)]
          s.gsub!(/\A\n/, '') if last_state
          s.gsub!(/(?<=\n)[ \t]*\Z/, '') if new_state && new_state != :l10n
          unless s.empty?
            ios << "\n_.call(#{s.inspect})"
          end
        end
        if new_index
          if new_state == :outer
            case state
            when :code_line, :code_span then
              ios << "\n#{src[index...new_index].strip}"
            when :code_print then
              ios << "\n_.call(#{src[index...new_index].strip})"
            when :code_template then
              ios << "\n(#{src[index...new_index].strip}).call(_)"
            when :l10n then
              localize(ios, src[index...new_index].strip)
            end
          end
          index = new_index + match.length
          last_state = state unless state == :code_comment
          state = new_state
        end
      end until new_index.nil?
      if klass && sym
        ios << "\n_.call('')" unless PRINT_STATES.include? last_state
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