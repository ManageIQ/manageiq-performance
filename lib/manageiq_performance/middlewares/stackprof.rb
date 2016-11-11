begin
  require 'stackprof'

  module ManageIQPerformance
    module Middlewares
      module Stackprof

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

          if results = StackProf.results
            save_report generic_report_filename(env, :stackprof),
                        stackprof_short_form_data,
                        stackprof_long_form_data(results)
          end
        end

        def stackprof_long_form_data results
          proc { Marshal.dump(results) }
        end

        def stackprof_short_form_data
          proc {}
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
