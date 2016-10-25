namespace :miq_performance do
  begin
    require "stackprof"

    desc "Analyze"
    task :stackprof_analyze, [:dir, :method] do |t, args|
      args.with_defaults :method => nil

      # Prevents the `help` from the Analyze command from being show with all
      # of the CLI args that wouldn't work for this task.
      fail "Error:  Dir required" unless args[:dir]

      require "miq_performance/commands/analyze"
      opts =  [args[:dir]]
      opts += ["--method", args[:method]] if args[:method]
      MiqPerformance::Commands::Analyze.run(opts)
    end

    desc "Analyze, with stackprof, a route in the first suite"
    task :stackprof_first, [:method, :route_index] do |t, args|
      Rake::Task["miq_performance:stackprof_analyze"].invoke "--first", args[:method]
    end

    desc "Analyze, with stackprof, a route in the last suite"
    task :stackprof_last, [:method, :route_index] do |t, args|
      Rake::Task["miq_performance:stackprof_analyze"].invoke "--last", args[:method]
    end

  rescue LoadError
    # The `stackprof` gem is not installed, so not defining stackprof tasks
  end
end

