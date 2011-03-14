module Rack
  describe FrozenRoute do

    before :each do
      default_result = @default_result
      @app = Rack::Builder.new {
        use Rack::FrozenRoute, %r{/frozen/?}, 'text/plain', 'frozen'
        run proc {|env| [200, {'Content-Type' => 'text/plain'}, 'default'] }
      }.to_app
    end

    it 'should return the specified body on matching route' do
      @app.call({})[2].should == 'default'
      @app.call({'PATH_INFO' => '/frozen'})[2].should == 'frozen'
    end

    it 'should return an ETag header on each request' do
      @app.call({'PATH_INFO' => '/frozen'})[1].should include 'ETag'
    end

    it 'should return 304 and an empty body on subsequent requests' do
      etag = @app.call({'PATH_INFO' => '/frozen'})[1]['ETag']
      result = @app.call({
        'PATH_INFO' => '/frozen',
        'HTTP_IF_NONE_MATCH' => etag
      })
      result[0].should == 304
      result[2].should be_empty
    end

  end # describe FrozenRoute
end # Rack
