namespace :miq_performance do
  desc "Benchmark the application"
  task :benchmark => :environment do
    require "miq_performance/commands/benchmark"
    MiqPerformance::Commands::Benchmark.run(["--requestfile"])
  end

  desc "Perform a benchmark on a specified URL"
  task :benchmark_url, [:url] do |t, args|
    # Prevents the `help` from the Benchmark command from being show with all
    # of the CLI args that wouldn't work for this task.
    fail "Error:  URL required" unless args[:url]

    require "miq_performance/commands/benchmark"
    MiqPerformance::Commands::Benchmark.run([args[:url]])
  end

  desc "Build a RequestFile for benchmarking"
  task :build_request_file => :environment do
    MiqPerformance::Reporting::RequestfileBuilder.new
  end
end
