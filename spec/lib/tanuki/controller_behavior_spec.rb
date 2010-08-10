require 'tanuki/context'
require 'tanuki/controller_behavior'
require 'tanuki/loader'
require 'tanuki/template_compiler'
require 'rack/utils'

module Tanuki
  ctx = Context.new.child
  ctx.app_root = 'app'
  ctx.cache_root = 'cache'
  Loader.context = ctx
end

describe Tanuki_Controller do

  before :all do
    ctx = Tanuki::Context.new.child
    ctx.app_root = 'app'
    ctx.cache_root = 'cache'
    Tanuki::Loader.context = ctx
  end

  it 'should have empty argument definitions when created' do
    C = Class.new(Tanuki_Controller)
    C.arg_defs.should == {}
  end

  it 'should have expected argument definitions when they are declared' do
    # class declaration
    class C < Tanuki_Controller
      has_arg :a, 42
      has_arg :b, 69
    end
    # end class declaration
    C.arg_defs.should == {:a => {:arg => 42, :index => 0}, :b => {:arg => 69, :index => 1}}
  end

  it 'should inherit argument definitions from parent controllers' do
    # class declaration
    class C < Tanuki_Controller
      has_arg :a, 42
    end
    class D < C
      has_arg :b, 69
    end
    # end class declaration
    C.arg_defs.should == {:a => {:arg => 42, :index => 0}}
    D.arg_defs.should == {:a => {:arg => 42, :index => 0}, :b => {:arg => 69, :index => 1}}
  end

  it 'should initialize default values when arguments are extracted' do
    # class declaration
    class C < Tanuki_Controller
      has_arg :a, 42
      has_arg :b, 69
      has_arg :c, 17
    end
    # end class declaration
    C.extract_args({}).should == [nil, nil, nil]
    C.extract_args({:c => 3, :a => 1}).should == [1, nil, 3]
    C.extract_args({:b => 2, :a => 1, :c => 3, :d => 4}).should == [1, 2, 3]
  end

  it 'should process arguments received in route part' do
    # class declaration
    class C < Tanuki_Controller
      has_arg :a, Tanuki_Argument_Integer.new(42)
      has_arg :b, Tanuki_Argument_Integer.new(69)
      has_arg :c, Tanuki_Argument_Integer.new(17)
      def initialize_route(*args)
        args.should == [1, 2, 3]
      end
    end
    # end class declaration
    c = C.new(nil, Class.new(Tanuki_Controller).new(nil, nil, nil), {:route => 'pie', :args => [1, 2, 3]})
    c.instance_variable_get(:@_args).should == {:a => 1, :b => 2, :c => 3}
  end

  it 'should initialize default values when received arguments are invalid' do
    # class declaration
    class C < Tanuki_Controller
      has_arg :a, Tanuki_Argument_Integer.new(42)
      has_arg :b, Tanuki_Argument_Integer.new(69)
      has_arg :c, Tanuki_Argument_Integer.new(17)
      def initialize_route(*args)
        args.should == [42, 69, 17]
      end
    end
    # end class declaration
    c = C.new(nil, Class.new(Tanuki_Controller).new(nil, nil, nil), {:route => 'pie', :args => ['a', 'b', 'c']})
    c.instance_variable_get(:@_args).should == {:a => 42, :b => 69, :c => 17}
  end

  it 'should have empty child definitions when created' do
    # class declaration
    class C < Tanuki_Controller
    end
    # end class declaration
    c = C.new(nil, nil, nil)
    c.ensure_configured!
    c.instance_variable_get(:@_child_defs).should == {}
  end

  it 'should have expected child definitions when they are declared' do
    # class declaration
    class C < Tanuki_Controller
      def configure
        has_child C, :x, model * 2
        has_child C, :y, model * 2 + 1
      end
    end
    # end class declaration
    c = C.new(nil, nil, nil, 1)
    c.model.should == 1
    c.ensure_configured!
    c.instance_variable_get(:@_child_defs).should == {
      :x => {:class => C, :model => 2, :hidden => false},
      :y => {:class => C, :model => 3, :hidden => false}
    }
  end

  it 'should build links according to argument and child definitions' do
    # class declaration
    class C < Tanuki_Controller
      has_arg :a, Tanuki_Argument_Integer.new(42)
      has_arg :b, Tanuki_Argument_Integer.new(69)
      def configure
        has_child C, :x, model * 2
        has_child C, :y, model * 2 + 1
      end
    end
    # end class declaration
    c = C.new(nil, nil, nil, 1)
    a = c[:x]
    b = c[:y]
    a.model.should == 2
    b.model.should == 3
    c.instance_variable_get(:@_cache).keys.should == [[:x, []], [:y, []]]
    c[:y, 2].should equal c[:y, 2]
    c[:x][:x][:x].model.should == 8
    c.link.should == '/'
    c[:x][:y][:x].link.should == '/x/y/x'
    c[:x, 1][:y, 'a', 3].link.should == '/x:a-1/y:b-3'
    c[:x, :b => 2].link.should == '/x:b-2'
  end

end