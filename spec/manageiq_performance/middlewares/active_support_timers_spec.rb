require "active_support/notifications"
require "manageiq_performance/middleware"
require "manageiq_performance/middlewares/active_support_timers"

class FakeTimersMiddleware
  include ManageIQPerformance::Middlewares::ActiveSupportTimers

  def initialize
    active_support_timers_initialize
  end

  private

  def save_report env, info, short, long
  end
end

describe ManageIQPerformance::Middlewares::ActiveSupportTimers do
  let(:sample_timer_data) {
    {
      "controller" => "FooController",
      "action"     => "index",
      "path"       => "/foos",
      "format"     => "html",
      "status"     => 200,
      "time"       => {
        "views"         => 5,
        "activerecord"  => 20,
        "total"         => 26
      }
    }
  }
  let(:short_data) { subject.send :active_support_timers_short_form_data }
  let(:long_data)  { subject.send :active_support_timers_long_form_data  }

  describe "#active_support_timers_finish" do
    subject { FakeTimersMiddleware.new }

    context "with timer data set in the Thread variable" do
      before { Thread.current[:miq_perf_request_timer_data] = sample_timer_data }

      it "saves the data" do
        env = {"MIQ_PERFORMANCE_END_TIME" => 1026000}
        expect(subject).to receive(:save_report).with(env, :info, short_data, long_data)

        subject.send :active_support_timers_finish, env
      end
    end

    context "with timer data not set in the Thread variable" do
      it "does not save the data if MIQ_PERF_TIMESTAMP is not set in the env" do
        env = {"MIQ_PERFORMANCE_END_TIME" => 1026000}
        expect(subject).to receive(:save_report).never

        subject.send :active_support_timers_finish, env
      end

      it "saves the the data with a timestamp generated from MIQ_PERF_TIMESTAMP and MIQ_PERFORMANCE_END_TIME" do
        env = {"HTTP_MIQ_PERF_TIMESTAMP" => 1000000, "MIQ_PERFORMANCE_END_TIME" => 1026000}
        expect(subject).to receive(:save_report).with(env, :info, short_data, long_data)

        subject.send :active_support_timers_finish, env
      end

      it "does not blow up in HTTP_MIQ_PERF_TIMESTAMP is sent as a string" do
        env = {"HTTP_MIQ_PERF_TIMESTAMP" => "1000000", "MIQ_PERFORMANCE_END_TIME" => 1026000}
        expect(subject).to receive(:save_report).with(env, :info, short_data, long_data)

        subject.send :active_support_timers_finish, env
      end
    end

    after { Thread.current[:miq_perf_request_timer_data] = nil }
  end
end
