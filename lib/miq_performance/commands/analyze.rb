require "miq_performance/configuration"

begin
  require "stackprof"

  module MiqPerformance
    module Commands
      class Analyze
        def self.help_text
          "use perf tools to analyze the results"
        end

        def self.run(args)
          new(args).run
        end

        def initialize(args)
          @opts     = {}
          option_parser.parse!(args)
          @opts[:run_dir] ||= args.first
        end

        def run
          puts set_route_dir
          report = build_unified_report

          if @opts[:method]
            report.__walk_method_stack(@opts[:method])
          else
            report.print_text(false, 30)
          end
        end

        private

        def option_parser
          @optparse ||= OptionParser.new do |opt|
            opt.banner = "Usage: #{File.basename $0} analyze [options] [dir]"

            opt.separator ""
            opt.separator self.class.help_text.capitalize
            opt.separator ""
            opt.separator "Options"

            opt.on("-f",     "--first",       "Analyze first suite",   first_dir)
            opt.on("-l",     "--last",        "Analyze on last suite", last_dir)
            opt.on("-mNAME", "--method=NAME", "Method to analyze",     walk_method)
            opt.on("-h",     "--help",        "Show this message") { puts opt; exit }
          end
        end

        def sorted_dirs
          Dir["#{MiqPerformance.config.default_dir}/run_*"].sort
        end

        def first_dir
          Proc.new { @opts[:run_dir] = sorted_dirs.first }
        end

        def last_dir
          Proc.new { @opts[:run_dir] = sorted_dirs.last }
        end

        def walk_method
          Proc.new {|name| @opts[:method] = name }
        end

        def set_route_dir
          if Dir["#{@opts[:run_dir]}/*.stackprof"].empty?
            route_dirs = Dir["#{@opts[:run_dir]}/*"].sort

            if route_dirs.length == 1
              selection = 0
            else
              puts "Select route to analyze:"
              route_dirs.each_with_index do |route, index|
                printf "%2d)  %s\n", index + 1, route
              end

              # Pick selection
              printf "> "
              selection = STDIN.gets.chomp.to_i - 1
              puts "\n\n"
            end

            @route_dir = route_dirs[selection]
          else
            @route_dir = @opts[:run_dir]
          end
        end

        # Ripped straight from `stackprof`'s bin file
        def build_unified_report
          reports = []
          Dir["#{@route_dir}/*.stackprof"].each do |file|
            begin
              reports << StackProf::Report.new(Marshal.load(IO.binread(file)))
            rescue TypeError => e
              STDERR.puts "** error parsing #{file}: #{e.inspect}"
            end
          end
          reports.inject(:+)
        end
      end
    end
  end

  # TODO:  DELETE ME
  #
  # This is a hack for Stackprof while the `walk_method` PR:
  #
  #   https://github.com/tmm1/stackprof/pull/70
  #
  # still remains in Limbo, so we can make use of the functionality.  This is a
  # complete rip from that PR, minus renaming the method, so that it is
  # available here.  When available in the gem proper, remove this method and
  # update the caller to use the proper one.
  module StackProf
    class Report

      def __walk_method_stack(name)
        method_choice  = /#{Regexp.escape name}/
        invalid_choice = false

        # Continue walking up and down the stack until the users selects "exit"
        while method_choice != :exit
          print_method method_choice unless invalid_choice
          STDOUT.puts "\n\n"

          # Determine callers and callees for the current frame
          new_frames  = frames.select  {|_, info| info[:name] =~ method_choice }
          new_choices = new_frames.map {|frame, info| [
            callers_for(frame).sort_by(&:last).reverse.map(&:first),
            (info[:edges] || []).map{ |k, w| [data[:frames][k][:name], w] }.sort_by{ |k,v| -v }.map(&:first)
          ]}.flatten + [:exit]

          # Print callers and callees for selection
          STDOUT.puts "Select next method:"
          new_choices.each_with_index do |method, index|
            STDOUT.printf "%2d)  %s\n", index + 1, method.to_s
          end

          # Pick selection
          STDOUT.printf "> "
          selection = STDIN.gets.chomp.to_i - 1
          STDOUT.puts "\n\n\n"

          # Determine if it was a valid choice
          # (if not, don't re-run .print_method)
          if new_choice = new_choices[selection]
            invalid_choice = false
            method_choice = new_choice == :exit ? :exit : %r/^#{Regexp.escape new_choice}$/
          else
            invalid_choice = true
            STDOUT.puts "Invalid choice.  Please select again..."
          end
        end
      end
    end
  end
rescue LoadError
  # The `stackprof` gem is not installed, so not defining analyze command
end
