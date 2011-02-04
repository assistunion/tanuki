require 'tanuki/template_compiler'

module Tanuki
  describe TemplateCompiler do

    before :all do
      @ios = StringIO.new
    end

    before :each do
      @ios.seek 0
      @ios.truncate 0
    end

    it 'should treat outer code as printable strings' do
      TemplateCompiler.compile(@ios, 'hello')
      @ios.string.should == %Q{\n_.("hello",ctx)}
    end

    it 'should treat % at the beginning of lines as Ruby code' do
      TemplateCompiler.compile(@ios, "% code\n  %code")
      @ios.string.should == %Q{\ncode\ncode}
    end

    it 'should treat <% %> and <% -%> as Ruby code' do
      TemplateCompiler.compile(@ios, "<% code %>\n  <% code -%>\ntext")
      @ios.string.should == %Q{\ncode\n_.("\\n  ",ctx)\ncode\n_.("text",ctx)}
    end

    it 'should treat <%= %> and <%= -%> as printable Ruby code' do
      TemplateCompiler.compile(@ios, 'text<%= code %>text')
      @ios.string.should == %Q{\n_.("text",ctx)\n_.((code),ctx)\n_.("text",ctx)}
    end

    it 'should treat <%! %> and <%! -%> as Ruby code that returns a template' do
      TemplateCompiler.compile(@ios, 'text<%! code %>text')
      @ios.string.should == %Q{\n_.("text",ctx)\n(code).(_,ctx)\n_.("text",ctx)}
    end

    it 'should treat <%_ %> and <%_ -%> as Ruby code that calls a visitor' do
      TemplateCompiler.compile(@ios, "<%_foo code %><%_foo(x, y) code %>")
      @ios.string.should == %Q{\nfoo_result=(code).(foo_visitor,ctx)\nfoo_result=(code).(foo_visitor(x, y),ctx)}
    end

    it 'should treat <%# %> and <%# -%> as comments' do
      TemplateCompiler.compile(@ios, "<% code %><%# comment -%>\ntext")
      @ios.string.should == %Q{\ncode\n_.("text",ctx)}
    end

    it 'should treat <%% and %%> as escaped <% and %>' do
      TemplateCompiler.compile(@ios, '<% code %>text<%% code %><% code %%><% code %>')
      @ios.string.should == %Q{\ncode\n_.("text<% code %>",ctx)\ncode %><% code}
    end

    it 'should treat %% at the beginning of lines as escaped %' do
      TemplateCompiler.compile(@ios, "% code\n%% code\n  % code\n  %% code")
      @ios.string.should == %Q{\ncode\n_.("% code\\n",ctx)\ncode\n_.("  % code",ctx)}
    end

    it 'should treat <l10n></l10n> as localization blocks' do
      TemplateCompiler.compile(@ios, '<l10n> foo <ru>ru code</ru> bar <en>en code</en> baz </l10n>')
      @ios.string.should == %Q{\ncase ctx.best_language [:ru,:en]\nwhen :ru then\n_.("ru code",ctx)} <<
        %Q{\nwhen :en then\n_.("en code",ctx)\nend}
    end

    it 'should parse wiki inserts' do
      code = TemplateCompiler.parse_wiki('[[/foo/bar?foo.bar:foo#bar]]')
      code.should == '<%! self.root[:foo][:bar].model[:foo][:bar].link_to(:foo).bar_view %>'
    end

    it 'should parse controller parts in wiki inserts' do
      code = TemplateCompiler.parse_wiki('[[./foo]]')
      code.should == '<%! self[:foo].link_view %>'
      code = TemplateCompiler.parse_wiki('[[../foo]]')
      code.should == '<%! self.logical_parent[:foo].link_view %>'
    end

    it 'should parse model parts in wiki inserts' do
      code = TemplateCompiler.parse_wiki('[[?]]')
      code.should == '<%! self.model.link_view %>'
      code = TemplateCompiler.parse_wiki('[[?foo]]')
      code.should == '<%! self.model[:foo].link_view %>'
    end

    it 'should parse link parts in wiki inserts' do
      code = TemplateCompiler.parse_wiki('[[:edit]]')
      code.should == '<%! self.link_to(:edit).link_view %>'
      code = TemplateCompiler.parse_wiki('[[:]]')
      code.should == '[[:]]'
    end

    it 'should parse template parts in wiki inserts' do
      code = TemplateCompiler.parse_wiki('[[#]]')
      code.should == '<%! self.default_view %>'
      code = TemplateCompiler.parse_wiki('[[#foo]]')
      code.should == '<%! self.foo_view %>'
    end

  end # describe TemplateCompiler
end # Tanuki
