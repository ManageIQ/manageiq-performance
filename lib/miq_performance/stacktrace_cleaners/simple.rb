module ManageIQPerformance
  module StacktraceCleaners
    class Simple
      def initialize
        @app_root = "#{::Rails.root.to_s}/"
      end

      def call(stacktrace=Kernel.caller)
       stacktrace.select { |line| line.include? @app_root }
                 .map    { |line| line.sub @app_root, '' }
      end
    end
  end
end
