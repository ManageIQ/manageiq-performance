namespace :manageiq_performance do
  desc "Display general metrics for a given run"
  task :report, [:run_dir] do |t, args|
    # Prevents the `help` from the Report command from being show with all
    # of the CLI args that wouldn't work for this task.
    fail "Error:  URL required" unless args[:run_dir]

    require "manageiq_performance/commands/report"
    ManageIQPerformance::Commands::Report.run([args[:run_dir]])
  end

  task :report_on_first do
    Rake::Task["manageiq_performance:report"].invoke "--first"
  end
  task :first_report => :report_on_first

  task :report_on_last do
    Rake::Task["manageiq_performance:report"].invoke "--last"
  end
  task :last_report => :report_on_last
end
