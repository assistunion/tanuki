require 'tanuki/context'
require 'tanuki/controller_base'
require 'tanuki/loader'
require 'tanuki/template_compiler'

module Tanuki
  describe Loader do

    before :all do
      @root_context = Tanuki::Context.new.child
      @root_context.app_root = 'app'
      @root_context.cache_root = 'cache'
      Loader.context = @root_context
    end

    it 'should find the path to missing application classes' do
      Loader.class_path(:'').should == File.join('app', '.rb')
      Loader.class_path(:Aa).should == File.join('app', 'aa', 'aa.rb')
      Loader.class_path(:AaBb).should == File.join('app', 'aa_bb', 'aa_bb.rb')
      Loader.class_path(:Aa_Bb).should == File.join('app', 'aa', 'bb', 'bb.rb')
      Loader.class_path(:Aa_BbCc).should == File.join('app', 'aa', 'bb_cc', 'bb_cc.rb')
      Loader.class_path(:AaBb_CcDd).should == File.join('app', 'aa_bb', 'cc_dd', 'cc_dd.rb')
    end

    it 'should remember templates it ran at least once for each request' do
      ctx = @root_context.child
      ctx.templates = {}
      result = ControllerBase.dispatch(ctx, ::Tanuki_Controller, '/')
      result.should be_a Hash
      result.keys.should == [:type, :controller]
      Loader.run_template(ctx.templates, result[:controller], :default)
      Loader.should have_template(ctx.templates, ::Tanuki_Controller, :default)
      ctx = @root_context.child
      ctx.templates = {}
      Loader.should_not have_template(ctx.templates, ::Tanuki_Controller, :default)
    end

    it 'should compile and run templates' do
      ctrl = ControllerBase.dispatch(@root_context.child, ::Tanuki_Controller, '/')[:controller]
      ctrl.should_receive(:default_view)
      FileUtils.rm Loader.instance_eval { compiled_template_path(::Tanuki_Controller, :default) }, :force => true
      Loader.run_template({}, ctrl, :default)
      ctrl = ControllerBase.dispatch(@root_context.child, ::Tanuki_Missing, '/')[:controller]
      ctrl.should_receive(:index_view)
      FileUtils.rm Loader.instance_eval { compiled_template_path(::Tanuki_Missing, :index) }, :force => true
      Loader.run_template({}, ctrl, :index)
    end

    it 'should find the path to compiled templates' do
      Loader.instance_eval { compiled_template_path(::Tanuki_Missing, :default) }.should ==
        File.join('cache', 'tanuki.missing', 'default.rb')
      Loader.instance_eval { compiled_template_path(::Tanuki_Missing, :index) }.should ==
        File.join('cache', 'tanuki.controller', 'index.rb')
    end

  end # end describe Loader
end # end Tanuki