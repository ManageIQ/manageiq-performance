require "optparse"

require "miq_performance/requestor"
require "miq_performance/reporting/requestfile_builder"

namespace :miq_performance do
  desc "Benchmark the application"
  task :benchmark => :environment do
    options              = {}
    options[:host]       = ENV['MIQ_HOST'] || ENV['CFME_HOST']
    options[:ignore_ssl] = ENV['DISABLE_SSL_VERIFY']
    request_file         = ENV['REQUESTFILE'] || ENV['REQUEST_FILE']

    requests  = MiqPerformance::Reporting::RequestfileBuilder.load request_file
    requestor = MiqPerformance::Requestor.new options

    requests.each do |request|
      requestor.public_send request[:method].downcase, request[:path]
    end
  end

  desc "Perform a benchmark on a specified URL"
  task :benchmark_url, [:url] do |t, args|
    options              = {}
    options[:host]       = ENV['MIQ_HOST'] || ENV['CFME_HOST']
    options[:ignore_ssl] = ENV['DISABLE_SSL_VERIFY']

    MiqPerformance::Requestor.new(options).get args[:url]
  end

  desc "Build a RequestFile for benchmarking"
  task :build_request_file => :environment do
    MiqPerformance::Reporting::RequestfileBuilder.new
  end
end
