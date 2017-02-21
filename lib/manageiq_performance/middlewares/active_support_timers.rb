module ManageIQPerformance
  module Middlewares
    module ActiveSupportTimers

      PROCESS_ACTION_NOTIFIER = "process_action.action_controller".freeze

      private

      def active_support_timers_initialize
        ActiveSupport::Notifications.subscribe PROCESS_ACTION_NOTIFIER do |*args|
          event = ActiveSupport::Notifications::Event.new(*args)
          if event.payload[:headers].env[performance_header]
            active_support_timers_save event
          end
        end
      end

      # no-op since we are collecting through ActiveSupport::Notifications
      def active_support_timers_start(env); end

      def active_support_timers_finish(env)
        if Thread.current[:miq_perf_request_timer_data].nil? and env["HTTP_MIQ_PERF_TIMESTAMP"]
          time = (env["MIQ_PERFORMANCE_END_TIME"].to_i - env["HTTP_MIQ_PERF_TIMESTAMP"].to_i) / 1000
          Thread.current[:miq_perf_request_timer_data] = {
            "path" => env["REQUEST_PATH"],
            "time" => { "total" => time }
          }
        end

        if Thread.current[:miq_perf_request_timer_data]
          save_report env, :info,
                      active_support_timers_short_form_data,
                      active_support_timers_long_form_data
        end
      ensure
        ActiveSupportTimers.query_data = nil
      end

      def active_support_timers_save event
        ActiveSupportTimers.query_data = parsed_data(event)
      end

      def active_support_timers_long_form_data
        proc { ActiveSupportTimers.query_data }
      end

      def active_support_timers_short_form_data
        proc do
          {
            "request"      => ActiveSupportTimers.query_data["path"],
            "total_time"   => ActiveSupportTimers.query_data["time"]["total"],
            "activerecord" => ActiveSupportTimers.query_data["time"]["activerecord"],
            "views"        => ActiveSupportTimers.query_data["time"]["views"]
          }
        end
      end

      def self.query_data
        Thread.current[:miq_perf_request_timer_data]
      end

      def self.query_data=(value)
        Thread.current[:miq_perf_request_timer_data] = value
      end

      def parsed_data(event)
        {
          "controller" => event.payload[:controller],
          "action"     => event.payload[:action],
          "path"       => event.payload[:path],
          "format"     => event.payload[:format],
          "status"     => event.payload[:status],
          "time"       => {
            "views"         => event.payload[:view_runtime],
            "activerecord"  => event.payload[:db_runtime],
            "total"         => event.duration
          }
        }
      end
    end
  end
end
