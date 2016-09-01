require 'miq_performance/middleware'

module MiqPerformance
  class MiddlewareRailtie < Rails::Railtie
    initializer "miq_performance.configure_middleware" do |app|
      # Make this the first middleware in the stack.
      # TODO: Make this order independent
      app.middleware.unshift MiqPerformance::Middleware
    end
  end
end
