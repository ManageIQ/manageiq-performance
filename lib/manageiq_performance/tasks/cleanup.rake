namespace :manageiq_performance do
  desc "Remove empty manageiq_performance suite directories"
  task :cleanup do
    require "manageiq_performance/commands/clean"
    ManageIQPerformance::Commands::Clean.run(["--verbose"])
  end

  desc "Delete manageiq_performance all suite directories"
  task :clear do
    require "manageiq_performance/commands/clean"
    ManageIQPerformance::Commands::Clean.run(["--all"])
  end
end
