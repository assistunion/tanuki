require 'tanuki/context'

module Tanuki
  describe Context do

    before :each do
      @ctx = Context.child
    end

    it 'should register missing entries' do
      @ctx.foo = 'bar'
      @ctx.foo.should == 'bar'
    end

    it 'should raise an error on reassignment' do
      @ctx.foo = 'bar'
      lambda { @ctx.foo = 'baz' }.should raise_error
    end

    it 'should allow to make independent child contexts' do
      child_ctx = @ctx.child
      child_ctx.superclass.should == @ctx
      child_ctx.should_not equal @ctx
      child_ctx.should_not equal @ctx.child
    end

    it 'should allow reassignment in child contexts' do
      @ctx.foo = 'bar'
      lambda { @ctx.child.foo = 'bar' }.should_not raise_error
    end

    it 'should not allow instantiation' do
      lambda { @ctx.new }.should raise_error
    end

    it "should not allow to redefine `child' and `method_missing' methods" do
      lambda { @ctx.child = nil }.should raise_error
      lambda { @ctx.method_missing = nil }.should raise_error
    end

    it 'should not allow instantiation' do
      lambda { @ctx.new }.should raise_error
    end

    it "should not allow to redefine `child' and `method_missing' methods" do
      lambda { @ctx.child = nil }.should raise_error
      lambda { @ctx.method_missing = nil }.should raise_error
    end

  end # end describe Context
end # end Tanuki