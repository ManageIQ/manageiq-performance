require "miq_performance/stacktrace_cleaners/rails"

describe MiqPerformance::StacktraceCleaners::Rails do
  before do
    # Rails doesn't include the `spec` dir in it's backtrace cleaner.
    # Normally, this wouldn't matter in practice, but since we are trying to
    # test the functionality of it, we are overwritting it here.
    stub_const("Rails::BacktraceCleaner::APP_DIRS_PATTERN", /^\/?(app|config|lib|test|spec)/)
  end

  describe "#call" do
    it "returns the stacktrace without trace including gem info" do
      # Line number matters with this one... just an FYI
      expect(subject.call).to eq [
        "spec/miq_performance/stacktrace_cleaners/rails_spec.rb:14:in `block (3 levels) in <top (required)>'"
      ]
    end
  end
end
