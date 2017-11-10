module ManageIQPerformance
  module Commands
    class Report
      def self.help_text
        "compile suite data and build a report"
      end

      def self.run(args)
        require "manageiq_performance/configuration"
        require "manageiq_performance/reporter"

        new(args).run
      end

      def initialize(args)
        @opts = {}
        option_parser.parse!(args)
        @opts[:run_dir] ||= args.first
      end

      def run
        ManageIQPerformance::Reporter.build @opts[:run_dir]
      end

      private

      def option_parser
        require "optparse"

        @optparse ||= OptionParser.new do |opt|
          opt.banner = "Usage: #{File.basename $0} report [options] [dir]"

          opt.separator ""
          opt.separator self.class.help_text.capitalize
          opt.separator ""
          opt.separator "Options"

          opt.on("-f", "--first", "Report on first suite", first_dir)
          opt.on("-l", "--last",  "Report on last suite",  last_dir)
          opt.on("-h", "--help",  "Show this message") { puts opt; exit }
        end
      end

      def sorted_dirs
        Dir["#{ManageIQPerformance.config.default_dir}/run_*"].sort
      end

      def first_dir
        Proc.new { @opts[:run_dir] = sorted_dirs.first }
      end

      def last_dir
        Proc.new { @opts[:run_dir] = sorted_dirs.last }
      end
    end
  end
end
