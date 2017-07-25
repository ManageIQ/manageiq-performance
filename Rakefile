require "rake/clean"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec) do |t, task_args|
  t.rspec_opts = "--format documentation"
end

Dir["tasks/*.rake"].each do |rake_task_file|
  load File.expand_path(rake_task_file)
end


task :default => :spec
