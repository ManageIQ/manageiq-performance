require "yaml"
require "fileutils"
require "manageiq_performance/configuration"

module ManageIQPerformance
  module MiddlewareStorage
    class File
      attr_reader :miq_performance_suite_dir

      def initialize
        create_suite_dir
      end

      def record env, filetype, _, file_data
        write_report_file filename(env, filetype), &file_data
      end

      # noop:  Files have already been written at this point
      def finalize; end

      private

      def create_suite_dir
        base_dir = ManageIQPerformance.config.default_dir
        suite_dir = ::File.join(base_dir, "run_#{Time.now.to_i}")
        FileUtils.mkdir_p(suite_dir)

        @miq_performance_suite_dir = suite_dir
      end

      def write_report_file report_filename
        filepath = ::File.join(miq_performance_suite_dir, report_filename)
        FileUtils.mkdir_p(::File.dirname filepath)
        ::File.open(filepath, 'wb') do |file_io|
          data = yield
          file_io.write data.is_a?(Hash) ? data.to_yaml : data
        end
        report_filename
      end

      def filename env, ext=:data
        request_path = format_path_for_filename env['REQUEST_PATH']
        timestamp    = request_timestamp env

        "#{request_path}/request_#{timestamp}.#{ext}"
      end

      def format_path_for_filename path
        request_path = path.to_s.gsub("/", "%")[1..-1]
        request_path = "root" if request_path == ""
        request_path
      end

      def request_timestamp env
        env['HTTP_MIQ_PERF_TIMESTAMP'] || Time.now.to_i
      end
    end
  end
end
