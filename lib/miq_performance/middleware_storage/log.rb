require "json"
require "logger"
require "fileutils"
require "miq_performance/configuration"

module ManageIQPerformance
  module MiddlewareStorage
    class Log

      def initialize
        create_log_file
        create_logger
      end

      def record _, data, __
        Thread.current[:miq_perf_log_store_data] ||= {}
        Thread.current[:miq_perf_log_store_data].merge! Hash(data.call)
      end

      def finalize
        write_to_log
      ensure
        Thread.current[:miq_perf_log_store_data] = nil
      end

      private

      def create_log_file
        base_dir = ManageIQPerformance.config.log_dir
        @log_file = ::File.join(base_dir, "miq_performance.log")
        FileUtils.mkdir_p(base_dir)
        FileUtils.touch(@log_file)
      end

      def create_logger
        @logger           = Logger.new @log_file
        @logger.level     = Logger::INFO
        @logger.formatter = proc {|_,_,_,msg| "#{msg.to_json}\n" }
      end

      def write_to_log
        @logger.info Thread.current[:miq_perf_log_store_data]
      end
    end
  end
end
