require 'tanuki'

module Tanuki
  describe Application do

    before :each do
      Application.instance_eval do
        Tanuki::Loader.context = Tanuki::Context.child
        root = File.expand_path('../../../..', __FILE__)
        Context.app_root = File.join(root, 'app')
        Context.gen_root = File.join(root, 'gen')
        Context.public_root = File.join(root, 'public')
        Context.root_page = ::Tanuki::Controller
        Context.missing_page = ::Tanuki::Page::Missing
        Context.development = true
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

    it 'should return a template method' do
      ctx = Application.instance_eval { Context.child }
      ctx.templates = {}
      ctx.resources = {}
      ctx.javascripts = {}
      ctx.request = Rack::Request.new({'REQUEST_METHOD' => 'GET'})
      tpl = ControllerBehavior.dispatch(ctx, ::Tanuki::Controller, '/')
      tpl.should be_a Method
      tpl.receiver.should be_a Tanuki::BaseBehavior
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
      Application.instance_eval { Context.i18n = false }
      result = Application.instance_eval { rack_app }.call({
        'REQUEST_METHOD' => 'GET',
        'PATH_INFO' => '/'
      })
      result[0].should == 200
      result[1].should be_a Hash
      result[1].should have_key 'Content-Type'
      result[2].public_methods.should include :each
    end

    it 'should have this block build pages with response code 404' do
      Application.instance_eval { Context.i18n = false }
      result = Application.instance_eval { rack_app }.call({
        'REQUEST_METHOD' => 'GET',
        'PATH_INFO' => '/missing'
      })
      result[0].should == 404
      result[1].should be_a Hash
      result[1].should have_key 'Content-Type'
      result[2].public_methods.should include :each
    end

    it 'should have this block build redirects with response code 302' do
      Application.instance_eval do
        Context.i18n = true
        Context.i18n_redirect = true
        Context.language = :ru
        Context.languages = [:ru]
      end
      result = Application.instance_eval { rack_app }.call({
        'REQUEST_METHOD' => 'GET',
        'PATH_INFO' => '/'
      })
      result[0].should == 302
      result[1].should be_a Hash
      result[1].should have_key 'Content-Type'
      result[1]['Location'].should == '/ru'
    end

  end # describe Application
end # Tanuki
