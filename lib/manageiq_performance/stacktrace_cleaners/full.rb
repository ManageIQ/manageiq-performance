module ManageIQPerformance
  module StacktraceCleaners
    class Full
      def call stacktrace = Kernel.caller
        stacktrace
      end
    end
  end
end
