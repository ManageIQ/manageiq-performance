require "rails/backtrace_cleaner"

module ManageIQPerformance
  module StacktraceCleaners
    class Rails
      def initialize
        @cleaner = ::Rails::BacktraceCleaner.new
      end

      def call(stacktrace=Kernel.caller)
        @cleaner.clean stacktrace
      end
    end
  end
end
