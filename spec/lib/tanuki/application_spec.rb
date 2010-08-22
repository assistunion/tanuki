require 'tanuki'

module Tanuki
  describe Application do

    before :each do
      Application.instance_eval do
        @context = Tanuki::Loader.context = Tanuki::Context.child
        @context.app_root = 'app'
        @context.cache_root = 'cache'
        @context.root_page = ::Tanuki_Controller
        @context.missing_page = ::Tanuki_Page_Missing
        @rack_middleware = {}
      end
    end

    it 'should add and remove Rack middleware' do
      middleware = Application.instance_eval { @rack_middleware }
      Application.use Integer, 0
      middleware.should include Integer
      Application.discard Integer
      middleware.should_not include Integer
    end

    it 'should add visitors to framework objects' do
      Application.visitor :string do s = ''; proc {|out| s << out } end
      ObjectBehavior.public_instance_methods.should include :string_visitor
      obj = 'obj'.extend(ObjectBehavior)
      obj.string_visitor.should be_a Proc
      sv = obj.string_visitor
      sv.call('a').should == 'a'
      sv.call('b').should == 'ab'
    end

    it 'should find the best available server' do
      random_servers = (0..3).map { (0...8).map { (65 + rand(25)).chr }.join.to_sym }
      Application.instance_eval { @context.server = random_servers }
      Rack::Handler.should_receive(:get).exactly(4).times.and_raise([LoadError, NameError].shuffle[0])
      lambda { Application.instance_eval { available_server } }.should raise_error
      Rack::Handler.should_receive(:get).with(random_servers[0].downcase).and_raise(LoadError)
      Rack::Handler.should_receive(:get).with(random_servers[1].downcase).and_raise(NameError)
      Rack::Handler.should_receive(:get).with(random_servers[2].downcase)
      Application.instance_eval { available_server }
    end

    it 'should build a response body' do
      ctx = Application.instance_eval { @context.child }
      ctx.templates = {}
      ctrl = ControllerBehavior.dispatch(ctx, ::Tanuki_Controller, '/')[:controller]
      Application.visitor :array do arr = []; proc {|out| arr << out } end
      Application.instance_eval { build_body(ctrl, ctx) }.should be_a Array
    end

    it 'should construct a Rack app block' do
      Application.instance_eval { rack_app }.should be_a Proc
    end

    it 'should have this block handle trailing slashes in request path' do
      result = Application.instance_eval { rack_app }.call({'REQUEST_PATH' => '/page/', 'QUERY_STRING' => 'q'})
      result[0].should == 301
      result[1].should be_a Hash
      result[1].should have_key 'Content-Type'
      result[1]['Location'].should == '/page?q'
    end

    it 'should have this block build pages with response code 200' do
      Application.instance_eval { @context.i18n = false }
      result = Application.instance_eval { rack_app }.call({'REQUEST_PATH' => '/'})
      result[0].should == 200
      result[1].should be_a Hash
      result[1].should have_key 'Content-Type'
      result[2].public_methods.should include :each
    end

    it 'should have this block build pages with response code 404' do
      Application.instance_eval { @context.i18n = false }
      result = Application.instance_eval { rack_app }.call({'REQUEST_PATH' => '/missing'})
      result[0].should == 404
      result[1].should be_a Hash
      result[1].should have_key 'Content-Type'
      result[2].public_methods.should include :each
    end

    it 'should have this block build redirects with response code 302' do
      Application.instance_eval do
        @context.i18n = true
        @context.language = :ru
        @context.languages = [:ru]
      end
      result = Application.instance_eval { rack_app }.call({'REQUEST_PATH' => '/'})
      result[0].should == 302
      result[1].should be_a Hash
      result[1].should have_key 'Content-Type'
      result[1]['Location'].should == '/ru'
    end

  end # end describe Application
end # end Tanuki