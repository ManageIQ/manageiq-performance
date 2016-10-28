require 'miq_performance/middleware'

module MiqPerformance
  class MiddlewareRailtie < Rails::Railtie
    initializer "miq_performance.configure_middleware" do |app|
      # Make this the first middleware in the stack.
      # TODO: Make this order independent
      app.middleware.unshift MiqPerformance::Middleware

      if MiqPerformance.config.browser_mode.enabled?
        require 'miq_performance/browser_mode_middleware'
        app.middleware.insert_before "MiqPerformance::Middleware", "MiqPerformance::BrowserModeMiddleware"
      end
    end
  end
end
