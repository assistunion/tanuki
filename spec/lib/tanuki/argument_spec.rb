require File.join('tanuki', 'argument')

module Tanuki

  describe Argument do

    it 'should add and remove argument and type associations' do
      Argument.instance_variable_get(:@assoc).should == {}
      Argument.store(Fixnum, Tanuki::Argument::Integer)
      Argument.instance_variable_get(:@assoc).should == {Fixnum => Tanuki::Argument::Integer}
      Argument.delete(Fixnum)
      Argument.instance_variable_get(:@assoc).should == {}
    end

    it 'should convert declared types to argument types' do
      Argument.store(Fixnum, Tanuki::Argument::Integer)
      Argument.store(Range, Tanuki::Argument::IntegerRange)
      Argument.to_argument(5).class.should == Argument::Integer
      Argument.to_argument(1..10).class.should == Argument::IntegerRange
    end

    it 'should convert types to String arguments by default' do
      Argument.to_argument(Object.new).class.should == Argument::String
    end

    it 'should pass additional method arguments to argument contructor' do
      Argument.to_argument(1..10, 5).default == 5
    end

  end # end describe Argument


  describe Argument::Base do

      it 'should initialize default and current values when created' do
        a = Argument::Base.new(5)
        a.default.should == 5
        a.value.should == 5
      end

      it 'should invoke a hook when setting a value' do
        a = Argument::Base.new(5)
        a.should_receive(:to_value).with('3')
        a.value = '3'
      end

      it 'should return a String representation of its value' do
        a = Argument::Base.new(5)
        a.to_s.should == '5'
      end

  end # end describe Argument::Base


  describe Argument::Integer do

    it 'should parse from String to Integer' do
      a = Argument::Integer.new(5)
      a.value = '3'
      a.value.should == 3
      a.value = 'whoops'
      a.value.should == 5
    end

  end # end describe Argument::Integer


  describe Argument::IntegerRange do

    it 'should set default value to first item in Range' do
      a = Argument::IntegerRange.new(1..10)
      a.default.should == 1
    end

    it 'should parse from String to Integer' do
      a = Argument::IntegerRange.new(1..10, 5)
      a.value = '3'
      a.value.should == 3
      a.value = 'whoops'
      a.value.should == 5
    end

    it 'should revert value to default when setting out of range' do
      a = Argument::IntegerRange.new(1..10, 5)
      a.value = 3
      a.value.should == 3
      a.value = 23
      a.value.should == 5
    end

  end # end describe Argument::IntegerRange


  describe Argument::String do

    it 'should remain a String when parsed' do
      a = Argument::String.new('s')
      a.value = Object
      a.value.should == 'Object'
    end

  end # end describe Argument::String

end # end Tanuki