require "manageiq_performance/commands/profile"

describe ManageIQPerformance::Commands::Profile do
  subject { described_class.new [] }
  describe "#render_partial" do
    context "require_tree_output" do
      it "renders nothing if @opts[:generate_require_tree] is missing" do
        expect(subject.render_partial "require_tree_output").to eq "\n\n"
      end

      context "with @opts[:generate_require_tree] set" do
        before { subject.send(:require_tree_flag).call true }

        it "renders setting require cost and printing children if @opt[:full_require_tree] is set" do
          expected = <<-REQUIRE_TREE_OUTPUT.__strip_heredoc
            TOP_REQUIRE.set_top_require_cost

            puts ""
            TOP_REQUIRE.print_sorted_children

          REQUIRE_TREE_OUTPUT

          expect(subject.render_partial "require_tree_output").to eq expected
        end

        it "renders setting require cost and printing summary if @opt[:require_tree_summary] is set" do
          subject.send(:tree_print).call false
          subject.send(:tree_summary).call true
          expected = <<-REQUIRE_TREE_OUTPUT.__strip_heredoc
            TOP_REQUIRE.set_top_require_cost


            puts ""
            TOP_REQUIRE.print_summary
          REQUIRE_TREE_OUTPUT

          expect(subject.render_partial "require_tree_output").to eq expected
        end

        it "renders everything if @opt[:full_require_tree] and @opt[:require_tree_summary] are set" do
          subject.send(:tree_print).call true
          subject.send(:tree_summary).call true
          expected = <<-REQUIRE_TREE_OUTPUT.__strip_heredoc
            TOP_REQUIRE.set_top_require_cost

            puts ""
            TOP_REQUIRE.print_sorted_children

            puts ""
            TOP_REQUIRE.print_summary
          REQUIRE_TREE_OUTPUT

          expect(subject.render_partial "require_tree_output").to eq expected
        end

        it "renders setting require cost if @opt[:full_require_tree] and @opt[:require_tree_summary] are unset" do
          subject.send(:tree_print).call false
          subject.send(:tree_summary).call false
          expected = <<-REQUIRE_TREE_OUTPUT.__strip_heredoc
            TOP_REQUIRE.set_top_require_cost


          REQUIRE_TREE_OUTPUT

          expect(subject.render_partial "require_tree_output").to eq expected
        end
      end
    end

    context "memory_output" do
      it "renders nothing if @opts[:print_memory] is missing" do
        expect(subject.render_partial "memory_output").to eq ""
      end

      it "renders memory output @opt[:print_memory] is set" do
        subject.send(:memory_flag).call true
        expected = <<-MEMORY_OUTPUT.__strip_heredoc
          puts ""
          puts "TOTAL_MEMORY_USED: \#{ManageIQPerformance::Utils::ProcessMemory.get}MiB"
        MEMORY_OUTPUT

        expect(subject.render_partial "memory_output").to eq expected
      end
    end

    context "time_profile_output" do
      it "renders nothing if @opts[:time_profile] is missing" do
        expect(subject.render_partial "time_profile_output").to eq ""
      end

      it "renders default template if @opts[:time_profile] is present" do
        subject.send(:timing_flag).call true
        expected = <<-TIME_PROFILE_OUTPUT.__strip_heredoc
          real_seconds = measurements.real % 60
          user_seconds = measurements.utime % 60
          sys_seconds  = measurements.stime % 60
          cu_seconds   = measurements.cutime % 60
          cs_seconds   = measurements.cstime % 60

          puts ""
          puts "Timings"
          puts "-------"
          puts "real    %dm%.3fs" % [(measurements.real - real_seconds),  real_seconds]
          puts "user    %dm%.3fs" % [(measurements.utime - user_seconds), user_seconds]
          puts "sys     %dm%.3fs" % [(measurements.stime - sys_seconds),  sys_seconds]
          puts "cuser   %dm%.3fs" % [(measurements.cutime - cu_seconds),  cu_seconds]
          puts "csys    %dm%.3fs" % [(measurements.cstime - cs_seconds),  cs_seconds]
        TIME_PROFILE_OUTPUT

        expect(subject.render_partial "time_profile_output").to eq expected
      end
    end

    context "miqperf_profile_output" do
      it "renders nothing if miqperf_profile? is missing" do
        expect(subject.render_partial "miqperf_profile_output").to eq ""
      end

      it "renders default template if miqperf_profile? is true" do
        expect(subject).to receive(:miqperf_profile?).and_return(true)
        expected = <<-MIQPERF_PROFILE_OUTPUT.__strip_heredoc
          if ManageIQPerformance.last_run[:queries]
            puts ""
            puts "Total time in SQL: \#{ManageIQPerformance.last_run[:queries][:queries].inject(0){ |s,r| s + r[:elapsed_time] }.round(2)} ms"
            puts "Total count queries \#{ManageIQPerformance.last_run[:queries][:total_queries]}"
            slowest_query = ManageIQPerformance.last_run[:queries][:queries].max_by{ |x| x[:elapsed_time] }
            puts "Slowest SQL query took \#{slowest_query[:elapsed_time]} ms: \\n" + slowest_query[:sql]
          end
        MIQPERF_PROFILE_OUTPUT

        expect(subject.render_partial "miqperf_profile_output").to eq expected
      end
    end

    context "stackprof_output" do
      context "when @stackprof_output is present" do
        let(:output) { Pathname.new "foo/bar/baz" }
        before { subject.instance_variable_set :@stackprof_output, output }

        it "renders file output script if using_stackprof? is present" do
          expect(subject).to receive(:using_stackprof?).and_return(true).twice
          expected = <<-STACKPROF_OUTPUT.__strip_heredoc
            if defined?(StackProf)
              stackprof_data = Marshal.dump(StackProf.results)
              File.write("#{output.expand_path}", stackprof_data, :mode => "wb")
            end
          STACKPROF_OUTPUT

          expect(subject.render_partial "stackprof_output").to eq expected
        end

        it "renders file output script if miqperf_profile? is present" do
          expect(subject).to receive(:miqperf_profile?).and_return(true)
          expected = <<-STACKPROF_OUTPUT.__strip_heredoc
            if defined?(StackProf)
              stackprof_data = ManageIQPerformance.last_run[:stackprof]
              File.write("#{output.expand_path}", stackprof_data, :mode => "wb")
            end
          STACKPROF_OUTPUT

          expect(subject.render_partial "stackprof_output").to eq expected
        end

        it "renders file output script if both using_stackprof? & miqperf_profile? are present" do
          allow(subject).to receive(:using_stackprof?).and_return(true)
          allow(subject).to receive(:miqperf_profile?).and_return(true)
          expected = <<-STACKPROF_OUTPUT.__strip_heredoc
            if defined?(StackProf)
              stackprof_data = Marshal.dump(StackProf.results)
              File.write("#{output.expand_path}", stackprof_data, :mode => "wb")
            end
          STACKPROF_OUTPUT

          expect(subject.render_partial "stackprof_output").to eq expected
        end
      end

      context "when @stackprof_output is nil" do
        before { subject.instance_variable_set :@stackprof_output, nil }

        it "renders the template getting data from stackprof if using_stackprof?" do
          expect(subject).to receive(:using_stackprof?).and_return(true).twice
          expected = <<-STACKPROF_OUTPUT.__strip_heredoc
            if defined?(StackProf)
              puts ""
              StackProf::Report.new(StackProf.results).print_text(false, 20)
            end
          STACKPROF_OUTPUT

          expect(subject.render_partial "stackprof_output").to eq expected
        end

        it "renders the template getting data from ManageIQPerformance if miqperf_profile?" do
          expect(subject).to receive(:miqperf_profile?).and_return(true).twice
          expected = <<-STACKPROF_OUTPUT.__strip_heredoc
            if defined?(StackProf)
              puts ""
              StackProf::Report.new(Marshal.load(ManageIQPerformance.last_run[:stackprof])).print_text(false, 20) if ManageIQPerformance.last_run[:stackprof]
            end
          STACKPROF_OUTPUT

          expect(subject.render_partial "stackprof_output").to eq expected
        end

        it "renders nothing if both using_stackprof? & miqperf_profile? are missing" do
          expect(subject).to receive(:using_stackprof?).and_return(false)
          expect(subject).to receive(:miqperf_profile?).and_return(false)
          expect(subject.render_partial "stackprof_output").to eq ""
        end
      end
    end
  end
end
