require 'fileutils'

namespace :miq_performance do
  desc "Remove empty miq_performance suite directories"
  task :cleanup do
    Dir["tmp/miq_performance/run_*"].each do |dir|
      if Dir["#{dir}/*"].empty?
        puts "Deleting #{dir}..."
        FileUtils.rm_rf dir
      end
    end
  end

  desc "Delete miq_performance all suite directories"
  task :clear do
    Dir["tmp/miq_performance/run_*"].each do |dir|
      FileUtils.rm_rf dir
    end
  end
end
