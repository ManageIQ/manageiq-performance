require "miq_performance/stacktrace_cleaners/simple"

module Rails
  def self.root
    File.expand_path File.join("..", "..", ".."), File.dirname(__FILE__)
  end
end

describe MiqPerformance::StacktraceCleaners::Simple do

  describe "#call" do
    context "default startpoint" do
      it "returns the stacktrace without trace including gem info" do
        # Line number matters with this one... just an FYI
        expect(subject.call).to eq [
          "spec/miq_performance/stacktrace_cleaners/simple_spec.rb:15:in `block (4 levels) in <top (required)>'"
        ]
      end
    end
  end
end
