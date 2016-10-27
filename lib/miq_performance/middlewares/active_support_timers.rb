module MiqPerformance
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
        filename = Thread.current[:miq_perf_request_timer_data].delete "filename"
        save_report filename do |f|
          f.write Thread.current[:miq_perf_request_timer_data].to_yaml
        end
      ensure
        Thread.current[:miq_perf_request_timer_data] = nil
      end

      def active_support_timers_save event
        Thread.current[:miq_perf_request_timer_data] = parsed_data(event)
      end

      def active_support_timers_filename event
        request_path = format_path_for_filename event.payload[:path]
        timestamp    = request_timestamp event.payload[:headers].env

        "#{request_path}/request_#{timestamp}.info"
      end

      def parsed_data(event)
        {
          "filename"   => active_support_timers_filename(event),
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
