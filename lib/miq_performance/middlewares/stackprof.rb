begin
  require 'stackprof'

  module MiqPerformance
    module Middlewares
      module Stackprof

        def self.included(klass)
          klass.performance_middleware << "stackprof"
        end

        private

        def stackprof_initialize
          @default_stackprof_raw      = false
          @default_stackprof_mode     = :wall
          @default_stackprof_interval = 1000
        end

        def stackprof_start env
          StackProf.start :mode     => stackprof_mode(env),
                          :interval => stackprof_interval(env),
                          :raw      => stackprof_raw(env)
        end

        # There is a performance hit here as we wait for the report to be written
        # to disk, but it will not be shown in the report.
        def stackprof_finish env
          StackProf.stop

          stackprof_save stackprof_report_filename(env)
        end

        def stackprof_save filename
          if results = StackProf.results
            filepath = File.join(miq_performance_session_dir, filename)
            FileUtils.mkdir_p(File.dirname filepath)
            File.open(filepath, 'wb') do |f|
              f.write Marshal.dump(results)
            end
            filename
          end
        end

        def stackprof_report_filename env
          request_path = format_path_for_filename env['REQUEST_PATH']
          timestamp    = request_timestamp env

          "#{request_path}/request_#{timestamp}.stackprof"
        end

        def stackprof_raw(env)
          !!env["HTTP_MIQ_PERF_STACKPROF_RAW"] || @default_stackprof_raw
        end

        def stackprof_mode(env)
          (env["HTTP_MIQ_PERF_STACKPROF_MODE"] || @default_stackprof_mode).to_sym
        end

        def stackprof_interval(env)
          (env["HTTP_MIQ_PERF_STACKPROF_INTERVAL"] || @default_stackprof_interval).to_i
        end
      end
    end
  end

rescue LoadError
  # The `stackprof` gem is not installed, so not defining this class
end
