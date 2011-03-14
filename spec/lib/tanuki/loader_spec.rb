require 'tanuki/extensions/module'
require 'tanuki/behavior/controller_behavior'
require 'tanuki/behavior/base_behavior'
require 'tanuki/context'
require 'tanuki/loader'
require 'tanuki/template_compiler'

module Tanuki
  describe Loader do

    before :all do
      @context = Tanuki::Context.child
      root = File.expand_path('../../../..', __FILE__)
      @context.app_root = File.join(root, 'app')
      @context.gen_root = File.join(root, 'gen')
      Loader.context = @context
      @context.missing_page = ::Tanuki::Page::Missing
      @context.request = Rack::Request.new({
        'REQUEST_METHOD' => 'GET',
        'PATH_INFO' => '/'
      })
      @context.response = Rack::Response.new([], 200, {})
    end

    it 'should find the path to missing application classes' do
      Loader.class_path(:'', @context.app_root).should == File.join(@context.app_root, '.rb')
      Loader.class_path(:'Aa', @context.app_root).should == File.join(@context.app_root, 'aa/aa.rb')
      Loader.class_path(:'AaBb', @context.app_root).should == File.join(@context.app_root, 'aa_bb/aa_bb.rb')
      Loader.class_path(:'Aa::Bb', @context.app_root).should == File.join(@context.app_root, 'aa/bb/bb.rb')
      Loader.class_path(:'Aa::BbCc', @context.app_root).should == File.join(@context.app_root, 'aa/bb_cc/bb_cc.rb')
      Loader.class_path(:'AaBb::CcDd', @context.app_root).should == File.join(@context.app_root, 'aa_bb/cc_dd/cc_dd.rb')
    end

    it 'should find template sources through receiver ancestors' do
      Loader.instance_eval { resource_owner(::Tanuki::Controller, :view) }.should ==
        [::Tanuki::Controller, File.join(@context.app_root, 'tanuki/controller/controller.view.thtml')]
      Loader.instance_eval { resource_owner(::Tanuki::Page::Missing, :link) }.should ==
        [::Tanuki::Controller, File.join(@context.app_root, 'tanuki/controller/controller.link.thtml')]
    end

    it 'should assemble the path to compiled templates' do
      Loader.instance_eval { compiled_template_path(::Tanuki::Page::Missing, :default) }.should ==
        File.join(@context.gen_root, 'tanuki/page/missing/default.tpl.rb')
    end

    it 'should remember templates it ran at least once for each request' do
      ctx = @context.child
      ctx.templates = {}
      result = ControllerBehavior.dispatch(ctx, ::Tanuki::Controller, '/')
      result.should be_a Method
      Loader.run_template(ctx.templates, result.receiver, :view)
      Loader.should have_template(ctx.templates, ::Tanuki::Controller, :view)
      ctx = @context.child
      ctx.templates = {}
      Loader.should_not have_template(ctx.templates, ::Tanuki::Controller, :view)
    end

    it 'should compile and run templates' do
      ctrl = ControllerBehavior.dispatch(@context.child, ::Tanuki::Controller, '/').receiver
      ctrl.should_receive(:view_view)
      FileUtils.rm Loader.instance_eval { compiled_template_path(::Tanuki::Controller, :view) }, :force => true
      Loader.run_template({}, ctrl, :view)
      ctrl = ControllerBehavior.dispatch(@context.child, ::Tanuki::Page::Missing, '/').receiver
      ctrl.should_receive(:link_view)
      FileUtils.rm Loader.instance_eval { compiled_template_path(::Tanuki::Page::Missing, :link) }, :force => true
      Loader.run_template({}, ctrl, :link)
    end

  end # describe Loader
end # Tanuki
