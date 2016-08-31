class MiqPerformance::RakeTasksRailtie < Rails::Railtie
  rake_tasks do
    load 'miq_performance/tasks/benchmark.rake'
  end
end
