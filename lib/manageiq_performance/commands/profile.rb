module ManageIQPerformance
  module Commands
    class Profile
      attr_reader :output

      DEFAULT_OPTS = {
        :target_type => :file,
        :full_require_tree => true,
        :stackprof_mode => :cpu,
        :stackprof_interval => 1000
      }

      def self.help_text
        "memory/timing profile of a single ruby script or application"
      end

      def self.run(args)
        new(args).run
      end

      def initialize(args)
        require "pathname"

        @opts         = DEFAULT_OPTS.dup
        @output       = STDOUT
        @cmd_root     = Pathname.new Dir.pwd
        @miqperf_root = Pathname.new File.expand_path("../..", __dir__)

        option_parser.parse!(args)
        @profile_target  = args.first
      end

      def run
        write_tmpfile
        run_wrapper_script    unless @opts[:debug]
        debug_wrapper_script  if @opts[:debug]
      ensure
        @run_wrapper.close!   if @run_wrapper
      end

      private

      def write_tmpfile
        require "erb"
        require "tempfile"

        @run_wrapper = Tempfile.new("run_wrapper")
        template_path = "../templates/profile_runner_wrapper.rb.erb"
        template = File.read File.expand_path(template_path, __dir__)

        @run_wrapper.tap do |wrapper|
          wrapper.write ERB.new(template, nil, "-").result(binding)
        end
      end

      def run_wrapper_script
        @run_wrapper.close # write the contents of the file to the path
        run_cmd
      end

      def debug_wrapper_script
        @run_wrapper.rewind
        puts "# Outout: #{@output == STDOUT ? "STDOUT" : @opt[:output_file]}"
        puts "# Wrapper file:  #{@run_wrapper.path}..."
        puts "# CMD:  #{command}"
        puts "#"
        puts "# --------------------"
        puts
        puts @run_wrapper.read
      end

      def run_cmd
        @output = File.open(@opts[:output_file], "w") if @opts[:output_file]
        env = {"RUBYOPT" => nil} # don't let bundler inject itself without our permission
        pid = Kernel.spawn env, command, [:out, :err] => output
        Process.wait pid
      end

      def command
        cmd  = "#{Gem.ruby} #{@run_wrapper.path} "
        cmd += @opts[:passthrough_args] if @opts[:passthrough_args]
        cmd += @profile_target if @opts[:target_type] == :rake
        cmd
      end

      def use_sysproctable?
        @use_sysproctable ||=
          begin
            if @opts[:sysproctable]
              require "sys/proctable"
            else
              false
            end
          rescue LoadError
            false
          end
      end

      def using_stackprof?
        @use_stackprof ||=
          begin
            if @opts[:stackprof_enabled]
              require "stackprof"
            else
              false
            end
          rescue LoadError
            false
          end
      end

      def option_parser
        require 'optparse'

        @optparse ||= OptionParser.new do |opt|
          opt.banner = "Usage: #{File.basename $0} proile [options] [TARGET]"

          opt.separator ""
          opt.separator self.class.help_text.capitalize
          opt.separator ""
          opt.separator "Pass a TARGET, which is a ruby script file or a rake  "
          opt.separator "task, that will be run in a subprocess with extra     "
          opt.separator "profiling.  Options add various things to profile, or "
          opt.separator "run the `-d`/`--debug`flag to print out the resulting "
          opt.separator "script to stdout (this can be piped into a another    "
          opt.separator "process if a subprocess is not desired).              "
          opt.separator ""

          opt.separator "Target Types"

          opt.on           "--file",               "Target is a ruby file (default)",   set_target(:file)
          opt.on           "--rake",               "Target is a rake task",             set_target(:rake)
          opt.on           "--rails",              "Args eval'd in rails context",      set_target(:rails)

          opt.separator ""

          opt.separator "Options"

          opt.on "-a",     "--args=ARGS",          "Args to pass to profiled file",     passthrough_args
          opt.on "-b",     "--[no-]bundler",       "Setup bundler when profiling",      include_bundler
          opt.on "-D",     "--[no-]debug",         "Debug the generated wrapper",       set_debug
          opt.on "-m",     "--[no-]mem",           "Print mem used for profile",        memory_flag
          opt.on           "--[no-]sys-proctable", "Use sys/proctable for mem",         sysproctable_flag
          opt.on "-oFILE", "--output=FILE",        "Output for report (def STDOUT)",    set_output
          opt.on "-pFILE", "--stackprof-out=FILE", "Output for stackprof",              stackprof_output
          opt.on "-r",     "--[no-]require-tree",  "Enable require tree report",        require_tree_flag
          opt.on           "--[no-]full-tree",     "Print full require tree",           tree_print
          opt.on           "--[no-]tree-summary",  "Print require tree summary",        tree_summary
          opt.on "-s",     "--[no-]stackprof",     "Enable stackprof when profiling",   stackprof_flag
          opt.on           "--prof-mode=MODE",     "Set stackprof mode (def 'cpu')",    stackprof_mode
          opt.on           "--prof-interval=INT",  "Set stackprof interval (def 1000)", stackprof_interval
          opt.on "-t",     "--[no-]time",          "Time the profile",                  timing_flag

          opt.on("-h",     "--help",               "Show this message") { puts opt; exit }
        end
      end

      def set_target(val)
        Proc.new { @opts[:target_type] = val }
      end

      def passthrough_args
        Proc.new {|val| @opts[:passthrough_args] = val }
      end

      def include_bundler
        Proc.new {|val| @opts[:include_bundler] = val }
      end

      def set_debug
        Proc.new {|val| @opts[:debug] = val }
      end

      def memory_flag
        Proc.new {|val| @opts[:print_memory] = val }
      end

      def sysproctable_flag
        Proc.new {|val| @opts[:sysproctable] = val }
      end

      def set_output
        Proc.new do |output_file|
          require "fileutils"

          FileUtils.touch output_file unless File.exist?(output_file)
          @opts[:output_file] = output_file
        end
      end

      def stackprof_output
        Proc.new do |stackprof_out|
          require "fileutils"

          FileUtils.touch stackprof_out unless File.exist?(stackprof_out)
          @stackprof_output = Pathname.new stackprof_out
        end
      end

      def require_tree_flag
        Proc.new {|val| @opts[:generate_require_tree] = val }
      end

      def tree_print
        Proc.new {|val| @opts[:full_require_tree] = val }
      end

      def tree_summary
        Proc.new {|val| @opts[:require_tree_summary] = val }
      end

      def stackprof_flag
        Proc.new {|val| @opts[:stackprof_enabled] = val }
      end

      def stackprof_mode
        Proc.new {|val| @opts[:stackprof_mode] = val }
      end

      def stackprof_interval
        Proc.new {|val| @opts[:stackprof_interval] = val }
      end

      def timing_flag
        Proc.new {|val| @opts[:time_profile] = val }
      end

    end
  end
end
