module ManageIQPerformance
  class RakeTasksRailtie < Rails::Railtie
    rake_tasks do
      load 'miq_performance/tasks/analyze.rake'
      load 'miq_performance/tasks/benchmark.rake'
      load 'miq_performance/tasks/cleanup.rake'
      load 'miq_performance/tasks/reporting.rake'
    end
  end
end
