require 'tanuki/context'

module Tanuki
  describe Context do

    before :each do
      @ctx = Context.new.child
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
      child_ctx.should be_a Context
      child_ctx.should_not equal @ctx
      child_ctx.should_not equal @ctx.child
    end

    it 'should allow reassignment in child contexts' do
      child_ctx = @ctx.child
      child_ctx.foo = 'bar'
      child_ctx = @ctx.child
      lambda { child_ctx.foo = 'bar' }.should_not raise_error
    end

  end # end describe Launcher
end # end Tanuki