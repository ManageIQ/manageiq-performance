begin
  # Autoload MiqQueue
  ::MiqQueue

  # Monkey Patch MiqQueue
  class ::MiqQueue < ApplicationRecord
    alias original_deliver deliver

    # Effectively wraps MiqQueue in a ManageIQPerformance.profile block, and
    # runs that normally.
    def deliver(requester = nil)
      name  = class_name
      name += ".find(#{instance_id})" if instance_id
      name += ".#{method_name}"

      # Remove any middleware that don't make sense to use with this
      # middleware:
      tmp_middleware  = ManageIQPerformance.config.middleware.reject do |mw|
        ManageIQPerformance::Middlewares::MiqQueueTimers::CONFLICTING_MIDDLEWARE.include?(mw)
      end
      changes = {"middleware" => tmp_middleware + ["miq_queue_timers"] }

      ManageIQPerformance.profile(name, :config_changes => changes) {
        original_deliver(requester)
      }
    end
  end

  module ManageIQPerformance
    module Middlewares
      module MiqQueueTimers

        CONFLICTING_MIDDLEWARE = %w[active_support_timers]

        private

        def miq_queue_timers_initialize; end

        # no-op since this is simply making use of the ENV that is set by
        # ManageIQPerformance.profile
        def miq_queue_timers_start(env); end

        def miq_queue_timers_finish(env)
          if env["HTTP_MIQ_PERF_TIMESTAMP"]
            time = (env["MIQ_PERFORMANCE_END_TIME"].to_i - env["HTTP_MIQ_PERF_TIMESTAMP"].to_i) / 1000
            Thread.current[:miq_perf_queue_timer_data] = {
              "item" => env["REQUEST_PATH"],
              "time" => time
            }
          end

          if Thread.current[:miq_perf_queue_timer_data]
            save_report env, :queue_info,
                        miq_queue_timers_short_form_data,
                        miq_queue_timers_long_form_data
          end
        ensure
          Thread.current[:miq_perf_queue_timer_data] = nil
        end

        def miq_queue_timers_long_form_data
          proc {
            class_name, *parts = Thread.current[:miq_perf_queue_timer_data]["item"].split(".")
            method_name        = parts.first if parts.size == 1
            instance_id, method_name = parts if parts.size == 2
            {
              "pid"         => Process.pid,
              "class_name"  => class_name,
              "method_name" => method_name,
              # remove "find(...)" in the "find(<<ID>>)", leaving <<ID>>
              "instance_id" => instance_id && instance_id.to_s[5..-2].to_i,
              "total_time"  => Thread.current[:miq_perf_queue_timer_data]["time"]
            }
          }
        end

        def miq_queue_timers_short_form_data
          proc do
            {
              "queue_item" => Thread.current[:miq_perf_queue_timer_data]["item"],
              "pid"        => Process.pid,
              "total_time" => Thread.current[:miq_perf_queue_timer_data]["time"]
            }
          end
        end
      end
    end
  end

rescue NameError
  # No-Op:  This probably means that MiqQueue is not defined, so lets move on
  # as if it hasn't been.
end
