namespace :miq_performance do
  desc "Remove empty miq_performance suite directories"
  task :cleanup do
    require "miq_performance/commands/clean"
    ManageIQPerformance::Commands::Clean.run(["--verbose"])
  end

  desc "Delete miq_performance all suite directories"
  task :clear do
    require "miq_performance/commands/clean"
    ManageIQPerformance::Commands::Clean.run(["--all"])
  end
end
