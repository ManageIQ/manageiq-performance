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
        @opts = {:action => :report}
        option_parser.parse!(args)
        @opts[:run_dir] ||= args.first
      end

      def run
        case @opts[:action]
        when :info, :memory, :queries
          open_in_editor @opts[:action]
        when :report
          ManageIQPerformance::Reporter.build @opts[:run_dir]
        else
          @optparse.help
        end
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

          opt.on("-f", "--first",   "Report on first suite",          first_dir)
          opt.on("-l", "--last",    "Report on last suite",           last_dir)
          opt.on("-n", "--num=NUM", "Report on N suite",     Integer, n_dir)

          opt.on("-i", "--info",    "Open *.info in editor")    { @opts[:action] = :info }
          opt.on("-m", "--memory",  "Open *.memory in editor")  { @opts[:action] = :memory }
          opt.on("-q", "--queries", "Open *.queries in editor") { @opts[:action] = :queries }
          opt.on("-h", "--help",    "Show this message")        { puts opt; exit }
        end
      end

      def editor
        ENV["EDITOR"] || "vi"
      end

      def sorted_dirs
        Dir["#{ManageIQPerformance.config.default_dir}/run_*"].sort
      end

      def first_dir
        Proc.new { @opts[:run_dir] = sorted_dirs.first }
      end

      def n_dir
        Proc.new do |n|
          # For the user, don't have this 0 indexed
          raise "Err: 0 is invalid! -n/--num is 1 indexed." if n == 0

          n = n - 1 if n > 0

          @opts[:run_dir] = sorted_dirs[n.to_i]
        end
      end

      def last_dir
        Proc.new { @opts[:run_dir] = sorted_dirs.last }
      end

      def open_in_editor type = :info
        exec "#{editor} #{dir_files type}"
      end

      def dir_files type = :info
        glob_pattern = File.join @opts[:run_dir], "**", "*.#{type}"
        Dir[glob_pattern].sort.join(" ")
      end
    end
  end
end
