module MiqPerformance
  module Middlewares
    module ActiveSupportTimers

      NOTIFIER = "process_action.action_controller".freeze

      def self.included(klass)
        klass.performance_middleware << "activesupport_timers"
      end

      private

      def activesupport_timers_initialize
        ActiveSupport::Notifications.subscribe NOTIFIER do |*args|
          event = ActiveSupport::Notifications::Event.new(*args)
          if event.payload[:headers].env[performance_header]
            activesupport_timers_save event, parsed_data(event)
          end
        end
      end

      # no-op since we are collecting through ActiveSupport::Notifications
      def activesupport_timers_start(env); end
      def activesupport_timers_finish(env); end

      def activesupport_timers_save event, datas
        filename = activesupport_timers_filename event
        filepath = File.join(miq_performance_session_dir, filename)
        FileUtils.mkdir_p(File.dirname filepath)
        File.open(filepath, 'wb') do |f|
          f.write datas.to_yaml
        end
        filename
      end

      def activesupport_timers_filename event
        request_path = format_path_for_filename event.payload[:path]
        timestamp    = request_timestamp event.payload[:headers].env

        "#{request_path}/request_#{timestamp}.info"
      end

      def parsed_data(event)
        {
          'controller' => event.payload[:controller],
          'action'     => event.payload[:action],
          'path'       => event.payload[:path],
          'format'     => event.payload[:format],
          'status'     => event.payload[:status],
          'time'       => {
            'views'         => event.payload[:view_runtime],
            'activerecord'  => event.payload[:db_runtime],
            'total'         => event.duration
          }
        }
      end
    end
  end
end
