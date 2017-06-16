module ManageIQPerformance
  module MiddlewareStorage
    class Memory
      attr_reader :current_run, :profile_captures

      def initialize
        @current_run = {}
        @profile_captures = []
        ManageIQPerformance.last_run = nil
      end

      def record _, tag, __, data
        @current_run[tag] = data.call
      end

      def finalize
        @profile_captures << @current_run
        ManageIQPerformance.last_run = @current_run
        @current_run = {}
      end
    end
  end

  @memory_storage_mutex = Mutex.new
  @memory_storage_mutex.synchronize { @last_run = nil }

  def self.last_run= run_data
    @memory_storage_mutex.synchronize { @last_run = run_data }
  end

  def self.last_run
    @last_run
  end

end
