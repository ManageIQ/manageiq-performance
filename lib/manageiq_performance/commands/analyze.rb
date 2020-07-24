begin
  # Have this up top so we don't initialize this class if the stackprof dep
  # isn't available.
  require "stackprof"

  module ManageIQPerformance
    module Commands
      class Analyze
        def self.help_text
          "use perf tools to analyze the results"
        end

        def self.run(args)
          require "manageiq_performance/configuration"

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

          stackprof_report
        end

        private

        def option_parser
          require "optparse"

          @optparse ||= OptionParser.new do |opt|
            opt.banner = "Usage: #{File.basename $0} analyze [options] [dir]"

            opt.separator ""
            opt.separator self.class.help_text.capitalize
            opt.separator ""
            opt.separator "Options"

            opt.on("-f",     "--first",           "Analyze first suite",   first_dir)
            opt.on("-l",     "--last",            "Analyze on last suite", last_dir)
            opt.on("-mNAME", "--method=NAME",     "Method to analyze",     walk_method)
            opt.on(          "--[no-]flamegraph", "Generate flamegraph",   flamegraph)
            opt.on("-o",     "--open",            "Open generated graph ", open_flamegraph)

            opt.separator ""

            opt.on("-h",     "--help",            "Show this message") { puts opt; exit }
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

        def walk_method
          Proc.new {|name| @opts[:method] = name }
        end

        def flamegraph
          Proc.new {|val| @opts[:flamegraph] = val }
        end

        def open_flamegraph
          Proc.new {|val| @opts[:open_flamegraph] = val }
        end

        def stackprof_report
          if @opts[:flamegraph]
            flamegraph_for @report_dir
          elsif report = build_unified_report
            if @opts[:method]
              report.__walk_method_stack(@opts[:method])
            else
              report.print_text(false, 30)
            end
          end
        end

        def flamegraph_for report
          require 'tempfile'
          puts

          stackcollapse_file = Tempfile.new('stackcollapse')

          begin
            old_stdout, $stdout = $stdout, stackcollapse_file
            build_unified_report do |report|
              report.print_stackcollapse
            end
          ensure
            $stdout = old_stdout
          end

          stackcollapse_file.close

          cmd  = flamegraph_pl
          cmd += %Q' --title="#{flamegraph_title}"'
          cmd +=   " #{stackcollapse_file.path}"
          cmd +=   " > #{flamegraph_svg}"
          system cmd
        rescue => e
          puts "Error Generating Flamegraph!  #{e.message}"
        ensure
          stackcollapse_file.unlink
          if File.exist? flamegraph_svg
            if @opts[:open_flamegraph]
              exec "open #{flamegraph_svg}"
            else
              puts "Flamegraph generated:  #{flamegraph_svg}"
            end
          end
        end

        def flamegraph_pl
          ManageIQPerformance.config.custom_flamegraph_bin || begin
            stackprof_root = StackProf::Report.new({})
                                              .method(:print_text)
                                              .source_location
                                              .first
            fg_path = File.join(*%w[.. .. .. vendor FlameGraph flamegraph.pl])

            File.expand_path fg_path, stackprof_root
          end
        end

        def flamegraph_title
          "/#{File.basename(@route_dir).tr("%", "/")}"
        end

        def flamegraph_svg
          File.join @route_dir, "combined_flamegraph.svg"
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
          block_given? ? reports.each { |r| yield r } : reports.inject(:+)
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
