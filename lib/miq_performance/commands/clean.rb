require "optparse"
require "fileutils"
require "miq_performance/configuration"

module ManageIQPerformance
  module Commands
    class Clean
      attr_reader :opts

      def self.help_text
        "removes unneeded runs in the run dir"
      end

      def self.run(args)
        new(args).run
      end

      def initialize(args)
        @opts = {}
        option_parser.parse!(args)
      end

      def run
        Dir["#{ManageIQPerformance.config.default_dir}/run_*"].each do |dir|
          if opts[:all] or Dir["#{dir}/*"].empty?
            puts "Deleting #{dir}..." if opts[:verbose]
            FileUtils.rm_rf dir, opts.fetch(:dry_run, {})
          end
        end
      end

      private

      def option_parser
        OptionParser.new do |opt|
          opt.banner = "Usage: #{File.basename $0} clean [options]"

          opt.separator ""
          opt.separator self.class.help_text
          opt.separator ""
          opt.separator "Options"

          dry_run = Proc.new do
            @opts[:dry_run] = {:noop => true}
            @opts[:verbose] = true
          end

          opt.on("-a", "--all",     "Delete all dirs")   { @opts[:all] = true }
          opt.on("-v", "--verbose", "Show debug output") { @opts[:verbose] = true }
          opt.on("-d", "--dry-run", "Only display expected actions (noop)", dry_run)
          opt.on("-h", "--help",    "Show this message") { puts opt; exit }
        end
      end
    end
  end
end
