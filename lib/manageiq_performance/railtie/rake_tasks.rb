module ManageIQPerformance
  class RakeTasksRailtie < Rails::Railtie
    rake_tasks do
      load 'manageiq_performance/tasks/analyze.rake'
      load 'manageiq_performance/tasks/benchmark.rake'
      load 'manageiq_performance/tasks/cleanup.rake'
      load 'manageiq_performance/tasks/reporting.rake'
    end
  end
end
