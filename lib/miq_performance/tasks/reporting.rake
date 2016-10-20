require 'fileutils'
require 'miq_performance/reporter'

namespace :miq_performance do
  desc "Display general metrics for a given run"
  task :report, [:run_dir] do |t, args|
    dir = args[:run_dir]
    MiqPerformance::Reporter.build dir
  end

  task :report_on_first do
    dir = Dir["#{MiqPerformance.config.default_dir}/run_*"].sort.first
    Rake::Task["miq_performance:report"].invoke dir
  end
  task :first_report => :report_on_first

  task :report_on_last do
    dir = Dir["#{MiqPerformance.config.default_dir}/run_*"].sort.last
    Rake::Task["miq_performance:report"].invoke dir
  end
  task :last_report => :report_on_last
end

