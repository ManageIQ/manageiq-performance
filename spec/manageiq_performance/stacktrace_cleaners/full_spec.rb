require "manageiq_performance/stacktrace_cleaners/full"

describe ManageIQPerformance::StacktraceCleaners::Full do
  describe "#call" do
    it "returns the entire stacktrace" do
      stacktrace = caller
      expect(subject.call stacktrace).to eq stacktrace
    end

    it "defaults the stacktrace to caller" do
      # It is required to do `Thread.current.backtrace[1..-1]` here because
      # `caller` would not return the same result here as it would inside of
      # the `Full#call` method.
      #
      # Also, Thread.current.backtrace by itself adds an entry to the callstack
      # that is inside of the `Thread` module, so requesting everything after
      # the first entry is also needed.
      expected, result = [Thread.current.backtrace[1..-1], subject.call]
      expect(result).to eq expected
    end
  end
end
