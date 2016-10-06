module MiqPerformance
  class RakeTasksRailtie < Rails::Railtie
    rake_tasks do
      load 'miq_performance/tasks/benchmark.rake'
      load 'miq_performance/tasks/cleanup.rake'
    end
  end
end
