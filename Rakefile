require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |t, task_args|
  t.rspec_opts = "--format documentation"
end

task :default => :spec
