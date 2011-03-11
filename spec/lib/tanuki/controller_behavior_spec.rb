require 'tanuki'

module Tanuki
  @context = Context.child
  root = File.expand_path('../../../..', __FILE__)
  @context.app_root = File.join(root, 'app')
  @context.gen_root = File.join(root, 'gen')
  Loader.context = @context
end

describe Tanuki::Controller do

  before :all do
    @context = Tanuki::Context.child
    root = File.expand_path('../../../..', __FILE__)
    @context.app_root = File.join(root, 'app')
    @context.gen_root = File.join(root, 'gen')
    Tanuki::Loader.context = @context
    Tanuki::Argument.instance_eval { store(Fixnum, Tanuki::Argument::Integer) }
  end

  it 'should have empty argument definitions when created' do
    c = Class.new(Tanuki::Controller)
    c.arg_defs.should == {}
  end

  it 'should have expected argument definitions when they are declared' do
    c = Class.new(Tanuki::Controller)
    c.has_arg :a, 42
    c.has_arg :b, 69
    c.arg_defs.keys.should == [:a, :b]
    c.arg_defs[:a].keys.should == [:arg, :index]
    c.arg_defs[:b].keys.should == [:arg, :index]
    c.arg_defs[:a][:index].should == 0
    c.arg_defs[:b][:index].should == 1
  end

  it 'should inherit argument definitions from parent controllers' do
    c = Class.new(Tanuki::Controller)
    c.has_arg :a, 42
    d = Class.new(c)
    d.has_arg :b, 69
    c.arg_defs.keys.should == [:a]
    d.arg_defs.keys.should == [:a, :b]
  end

  it 'should initialize default values when arguments are extracted' do
    c = Class.new(Tanuki::Controller)
    c.has_arg :a, 42
    c.has_arg :b, 69
    c.has_arg :c, 17
    c.extract_args({}).should == [nil, nil, nil]
    c.extract_args({:c => 3, :a => 1}).should == [1, nil, 3]
    c.extract_args({:b => 2, :a => 1, :c => 3, :d => 4}).should == [1, 2, 3]
  end

  it 'should process arguments received in route part' do
    c = Class.new(Tanuki::Controller)
    c.has_arg :a, 42
    c.has_arg :b, 69
    c.has_arg :c, 17
    c.instance_eval { define_method(:initialize_route) {|*args| args.should == [1, 2, 3] } }
    c_obj = c.new(nil, Class.new(Tanuki::Controller).new(nil, nil, nil), {:route => 'pie', :args => [1, 2, 3]})
    c_obj.instance_variable_get(:@_args).should == {:a => 1, :b => 2, :c => 3}
  end

  it 'should initialize default values when received arguments are invalid' do
    c = Class.new(Tanuki::Controller)
    c.has_arg :a, 42
    c.has_arg :b, 69
    c.has_arg :c, 17
    c.instance_eval { define_method(:initialize_route) {|*args| args.should == [42, 69, 17] } }
    c_obj = c.new(nil, Class.new(Tanuki::Controller).new(nil, nil, nil), {:route => 'pie', :args => ['a', 'b', 'c']})
    c_obj.instance_variable_get(:@_args).should == {:a => 42, :b => 69, :c => 17}
  end

  it 'should have empty child definitions when created' do
    c_obj = Class.new(Tanuki::Controller).new(nil, nil, nil)
    c_obj.ensure_configured!
    c_obj.instance_variable_get(:@_child_defs).should == {}
  end

  it 'should have expected child definitions when they are declared' do
    c = Class.new(Tanuki::Controller)
    c.instance_eval do
      define_method(:configure) do
        has_child c, :x, model * 2
        has_child c, :y, model * 2 + 1
      end
    end
    c_obj = c.new(nil, nil, nil, 1)
    c_obj.model.should == 1
    c_obj.ensure_configured!
    c_obj.instance_variable_get(:@_child_defs).should == {
      :x => {:class => c, :model => 2, :hidden => false},
      :y => {:class => c, :model => 3, :hidden => false}
    }
  end

  it 'should build links according to argument and child definitions' do
    c = Class.new(Tanuki::Controller)
    c.has_arg :a, 42
    c.has_arg :b, 69
    c.instance_eval do
      define_method(:configure) do
        has_child c, :x, model * 2
        has_child c, :y, model * 2 + 1
      end
    end
    c_obj = c.new(nil, nil, nil, 1)
    a_obj = c_obj[:x]
    b_obj = c_obj[:y]
    a_obj.model.should == 2
    b_obj.model.should == 3
    c_obj.instance_variable_get(:@_cache).keys.should == [[:x, []], [:y, []]]
    c_obj[:y, 2].should equal c_obj[:y, 2]
    c_obj[:x][:x][:x].model.should == 8
    c_obj.link.should == '/'
    c_obj[:x][:y][:x].link.should == '/x/y/x'
    c_obj[:x, 1][:y, 'a', 3].link.should == '/x:a-1/y:b-3'
    c_obj[:x, :b => 2].link.should == '/x:b-2'
  end

end
