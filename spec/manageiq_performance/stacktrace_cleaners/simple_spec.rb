require "manageiq_performance/stacktrace_cleaners/simple"

describe ManageIQPerformance::StacktraceCleaners::Simple do

  describe "#call" do
    context "default startpoint" do
      it "returns the stacktrace without trace including gem info" do
        # Line number matters with this one... just an FYI
        expect(subject.call).to eq [
          "spec/manageiq_performance/stacktrace_cleaners/simple_spec.rb:9:in `block (4 levels) in <top (required)>'"
        ]
      end
    end
  end
end
