require 'tanuki'

module Tanuki
  describe Application do

    before :each do
      Application.instance_eval do
        @context = Tanuki::Loader.context = Tanuki::Context.child
        root = File.expand_path(File.join('..', '..', '..', '..'), __FILE__)
        @context.app_root = File.join(root, 'app')
        @context.gen_root = File.join(root, 'gen')
        @context.root_page = ::Tanuki::Controller
        @context.missing_page = ::Tanuki::Page::Missing
        @context.development = true
        @rack_middleware = []
      end
    end

    it 'should add and remove Rack middleware' do
      middleware = Application.instance_eval { @rack_middleware }
      Application.use Integer, 0
      Application.use Integer, 1
      middleware.find {|item| item[0] == Integer }.should_not be_nil
      Application.discard Integer
      middleware.find {|item| item[0] == Integer }.should be_nil
    end

    it 'should add visitors to framework objects' do
      Application.visitor :string do s = ''; proc {|out| s << out } end
      BaseBehavior.public_instance_methods.should include :string_visitor
      obj = 'obj'.extend(BaseBehavior)
      obj.string_visitor.should be_a Proc
      sv = obj.string_visitor
      sv.call('a').should == 'a'
      sv.call('b').should == 'ab'
    end

    it 'should build a response body' do
      ctx = Application.instance_eval { @context.child }
      ctx.templates = {}
      ctrl = ControllerBehavior.dispatch(ctx, ::Tanuki::Controller, '/')[:controller]
      Application.visitor :array do arr = []; proc {|out| arr << out } end
      Application.instance_eval { build_body(ctrl, ctx) }.should be_a Array
    end

    it 'should construct a Rack app block' do
      Application.instance_eval { rack_app }.should be_a Proc
    end

    it 'should have this block handle trailing slashes in request path' do
      result = Application.instance_eval { rack_app }.call({'PATH_INFO' => '/page/', 'QUERY_STRING' => 'q'})
      result[0].should == 301
      result[1].should be_a Hash
      result[1].should have_key 'Content-Type'
      result[1]['Location'].should == '/page?q'
    end

    it 'should have this block build pages with response code 200' do
      Application.instance_eval { @context.i18n = false }
      result = Application.instance_eval { rack_app }.call({'PATH_INFO' => '/'})
      result[0].should == 200
      result[1].should be_a Hash
      result[1].should have_key 'Content-Type'
      result[2].public_methods.should include :each
    end

    it 'should have this block build pages with response code 404' do
      Application.instance_eval { @context.i18n = false }
      result = Application.instance_eval { rack_app }.call({'PATH_INFO' => '/missing'})
      result[0].should == 404
      result[1].should be_a Hash
      result[1].should have_key 'Content-Type'
      result[2].public_methods.should include :each
    end

    it 'should have this block build redirects with response code 302' do
      Application.instance_eval do
        @context.i18n = true
        @context.i18n_redirect = true
        @context.language = :ru
        @context.languages = [:ru]
      end
      result = Application.instance_eval { rack_app }.call({'PATH_INFO' => '/'})
      result[0].should == 302
      result[1].should be_a Hash
      result[1].should have_key 'Content-Type'
      result[1]['Location'].should == '/ru'
    end

  end # describe Application
end # Tanuki
