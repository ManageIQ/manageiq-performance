require 'miq_performance/middleware'

module ManageIQPerformance
  class MiddlewareRailtie < Rails::Railtie
    initializer "miq_performance.configure_middleware" do |app|
      # Make this the first middleware in the stack.
      # TODO: Make this order independent
      app.middleware.unshift ManageIQPerformance::Middleware

      if ManageIQPerformance.config.browser_mode.enabled?
        require 'miq_performance/browser_mode_middleware'
        app.middleware.insert_before "ManageIQPerformance::Middleware", "ManageIQPerformance::BrowserModeMiddleware"
      end
    end
  end
end
