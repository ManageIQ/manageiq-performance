require 'fileutils'

# This is a wrapper middleware for the specific performance utility middlewares
# found in `lib/miq_performance/middlewares/`
module MiqPerformance
  class Middleware
    attr_reader :miq_performance_session_dir

    TIMESTAMP_HEADER = "HTTP_MIQ_PERF_TIMESTAMP".freeze
    PERFORMANCE_HEADER = "HTTP_WITH_PERFORMANCE_MONITORING".freeze
    PERFORMANCE_HEADER_ID = "PERFORMANCE_MONITORING_ID".freeze

    def self.performance_middleware
      @performance_middleware ||= []
    end

    def initialize app
      @app = app

      mk_suite_dir
      initialize_performance_middleware
    end

    def call env
      if env[PERFORMANCE_HEADER]
        performance_middleware_start env
      end
      response = @app.call env
      response[1][PERFORMANCE_HEADER_ID] = env[TIMESTAMP_HEADER]
      response
    ensure
      if env[PERFORMANCE_HEADER]
        performance_middleware_finish env
      end
    end

    private

    def performance_header
      ::MiqPerformance::Middleware::PERFORMANCE_HEADER
    end

    def performance_middleware
      self.class.performance_middleware
    end

    def initialize_performance_middleware
      performance_middleware.each do |middleware|
        send "#{middleware}_initialize"
      end
    end

    def performance_middleware_start env
      env[TIMESTAMP_HEADER] ||= Time.now.to_i
      performance_middleware.each do |middleware|
        send "#{middleware}_start", env
      end
    end

    def performance_middleware_finish env
      performance_middleware.reverse.each do |middleware|
        send "#{middleware}_finish", env
      end
    end

    def mk_suite_dir
      suite_dir = "tmp/miq_performance"
      suite_dir = File.join(suite_dir, "run_#{Time.now.to_i}")
      FileUtils.mkdir_p(suite_dir)

      @miq_performance_session_dir = suite_dir
    end

    def save_report filename
      filepath = File.join(miq_performance_session_dir, filename)
      FileUtils.mkdir_p(File.dirname filepath)
      File.open(filepath, 'wb') do |file_object|
        yield file_object
      end
      filename
    end

    def generic_report_filename env, ext=:data
      request_path = format_path_for_filename env['REQUEST_PATH']
      timestamp    = request_timestamp env

      "#{request_path}/request_#{timestamp}.#{ext}"
    end

    def format_path_for_filename path
      request_path = path.to_s.gsub("/", "-")[1..-1]
      request_path = "root" if request_path == ""
      request_path
    end

    def request_timestamp env
      env[TIMESTAMP_HEADER] || Time.now.to_i
    end
  end

  # TODO:  Automate the loading of this a bit better... also make it
  # configurable so you are able to exclude and add custom ones.
  require 'miq_performance/middlewares/stackprof'
  require 'miq_performance/middlewares/activesupport_timers'
  require 'miq_performance/middlewares/activerecord_queries'

  Middleware.send :include, Middlewares::Stackprof            if defined?(Middlewares::Stackprof)
  Middleware.send :include, Middlewares::ActiveSupportTimers  if defined?(Middlewares::ActiveSupportTimers)
  Middleware.send :include, Middlewares::ActiveRecordQueries  if defined?(Middlewares::ActiveRecordQueries)
end
