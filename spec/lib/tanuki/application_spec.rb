require 'tanuki'

module Tanuki
  describe Application do

    before :all do
      @root_context = Tanuki::Context.new
    end

    before :each do
      Application.set :app_root, 'app'
      Application.set :cache_root, 'cache'
    end

    it 'should find the path to missing application classes' do
      Application.class_path(:'').should == File.join('app', '.rb')
      Application.class_path(:Aa).should == File.join('app', 'aa', 'aa.rb')
      Application.class_path(:AaBb).should == File.join('app', 'aa_bb', 'aa_bb.rb')
      Application.class_path(:Aa_Bb).should == File.join('app', 'aa', 'bb', 'bb.rb')
      Application.class_path(:Aa_BbCc).should == File.join('app', 'aa', 'bb_cc', 'bb_cc.rb')
      Application.class_path(:AaBb_CcDd).should == File.join('app', 'aa_bb', 'cc_dd', 'cc_dd.rb')
    end

    it 'should add and remove Rack middleware' do
      middleware = Application.instance_eval { @rack_middleware }
      Application.use Rack::Reloader, 0
      middleware.should include Rack::Reloader
      Application.discard Rack::Reloader
      middleware.should_not include Rack::Reloader
    end

    it 'should remember templates it ran at least once for each request' do
      ctx = @root_context.child
      ctx.templates = {}
      Application.run_template(ctx.templates, Tanuki_Controller.dispatch(ctx, Tanuki_Controller, '/'), :default)
      Application.should have_template(ctx.templates, Tanuki_Controller, :default)
      ctx = @root_context.child
      ctx.templates = {}
      Application.should_not have_template(ctx.templates, Tanuki_Controller, :default)
    end

    it 'should compile and run templates' do
      ctrl = Tanuki_Controller.dispatch(@root_context.child, Tanuki_Controller, '/')
      ctrl.should_receive(:default_view)
      FileUtils.rm Application.instance_eval { compiled_template_path(Tanuki_Controller, :default) }, :force => true
      Application.run_template({}, ctrl, :default)
      ctrl = Tanuki_Controller.dispatch(@root_context.child, Tanuki_Missing, '/')
      ctrl.should_receive(:index_view)
      FileUtils.rm Application.instance_eval { compiled_template_path(Tanuki_Missing, :index) }, :force => true
      Application.run_template({}, ctrl, :index)
    end

    it 'should add visitors to framework objects' do
      Application.visitor :string do s = ''; proc {|out| s << out } end
      obj = ::Tanuki_Object.new
      obj.public_methods.should include :string_visitor
      obj.string_visitor.should be_a Proc
      sv = obj.string_visitor
      sv.call('a').should == 'a'
      sv.call('b').should == 'ab'
    end

    it 'should find the best available server' do
      random_servers = (0..3).map { (0...8).map { (65 + rand(25)).chr }.join.to_sym }
      Application.set :server, random_servers
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
      ctrl = Tanuki_Controller.dispatch(ctx, Tanuki_Controller, '/')
      Application.visitor :array do arr = []; proc {|out| arr << out } end
      Application.instance_eval { build_body(ctrl, ctx) }.should be_a Array
    end

    it 'should find the path to compiled templates' do
      Application.instance_eval { compiled_template_path(Tanuki_Missing, :default) }.should ==
        File.join('cache', 'tanuki.missing', 'default.rb')
      Application.instance_eval { compiled_template_path(Tanuki_Missing, :index) }.should ==
        File.join('cache', 'tanuki.controller', 'index.rb')
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

    it 'should have this block build pages' do
      Application.set :i18n, false
      Application.set :root_page, Tanuki_Controller
      result = Application.instance_eval { rack_app }.call({'REQUEST_PATH' => '/'})
      result[0].should == 200
      result[1].should be_a Hash
      result[1].should have_key 'Content-Type'
      result[2].public_methods.should include :each
      result = Application.instance_eval { rack_app }.call({'REQUEST_PATH' => '/missing'})
      result[0].should == 404
      result[1].should be_a Hash
      result[1].should have_key 'Content-Type'
      result[2].public_methods.should include :each
      Application.instance_eval { @context = Tanuki::Context.new.child }
      Application.set :i18n, true
      Application.set :language, :ru
      Application.set :languages, [:ru]
      result = Application.instance_eval { rack_app }.call({'REQUEST_PATH' => '/'})
      result[0].should == 302
      result[1].should be_a Hash
      result[1].should have_key 'Content-Type'
      result[1]['Location'].should == '/ru'
    end

    after :each do
      Application.instance_eval do
        @context = Tanuki::Context.new.child
        @rack_middleware = {}
      end
    end

  end # end describe Application
end # end Tanuki