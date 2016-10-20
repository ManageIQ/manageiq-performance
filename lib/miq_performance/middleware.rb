require "fileutils"
require "miq_performance/configuration"

# This is a wrapper middleware for the specific performance utility middlewares
# found in `lib/miq_performance/middlewares/`
module MiqPerformance
  class Middleware
    attr_reader :performance_middleware, :miq_performance_session_dir

    PERFORMANCE_HEADER = "HTTP_WITH_PERFORMANCE_MONITORING".freeze

    def initialize app
      @app = app
      @performance_middleware = []

      mk_suite_dir
      initialize_performance_middleware
    end

    def call env
      if env[PERFORMANCE_HEADER]
        performance_middleware_start env
      end
      @app.call env
    ensure
      if env[PERFORMANCE_HEADER]
        performance_middleware_finish env
      end
    end

    private

    def performance_header
      ::MiqPerformance::Middleware::PERFORMANCE_HEADER
    end

    def initialize_performance_middleware
      MiqPerformance.config.middleware.each do |name|
        begin
          require "miq_performance/middlewares/#{name}"

          module_name = name.split("_").map(&:capitalize).join
          middleware  = Object.const_get "MiqPerformance::Middlewares::#{module_name}"

          extend middleware
          @performance_middleware << name
        rescue NameError
        end
      end

      performance_middleware.each do |middleware|
        send "#{middleware}_initialize"
      end
    end

    def performance_middleware_start env
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
      base_dir = MiqPerformance.config.default_dir
      suite_dir = File.join(base_dir, "run_#{Time.now.to_i}")
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
      env['HTTP_MIQ_PERF_TIMESTAMP'] || Time.now.to_i
    end
  end
end
