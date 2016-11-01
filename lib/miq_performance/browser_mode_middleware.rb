require "fileutils"
require "miq_performance/configuration"

# This middleware wraps the existing `miq_performance/middleware` and allows
# for triggering that middleware from either a URL param, or have it always
# trigger the performance middleware.
#
# This is not enabled by default, and needs to be configured to have it
# included in the stack.
module MiqPerformance
  class BrowserModeMiddleware
    def initialize app
      @app = app
      set_performance_middleware_proc
    end

    def call env
      if enable_performance_middleware?
        env[Middleware::PERFORMANCE_HEADER] = "true"
      end
      @app.call env
    end

    private

    def enabled_performance_middleware?
      @enable_performance_middleware.call
    end

    def set_performance_middleware_proc
      if MiqPerformance.config.browser_mode.always_on?
        @enable_performance_middleware = proc { |env| true }
      else
        @enable_performance_middleware = proc do |env|
          env["QUERY_STRING"].include? "miq_performance_profile=true"
        end
      end
    end
  end
end
