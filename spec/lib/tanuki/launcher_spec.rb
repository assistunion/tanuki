require File.join('tanuki', 'launcher')

module Tanuki
  describe Launcher do

    it 'should have an each method that expects a block' do
      Launcher.new(nil, nil).should respond_to :each
    end

    it 'should build response body when iterated' do
      ctrl = mock('Controller', :default_view => proc {|p| p.call(42) })
      mock_proc = proc {}
      mock_proc.should_receive(:call).with '42'
      Launcher.new(ctrl, nil).each &mock_proc
    end

  end # end describe Launcher
end # end Tanuki