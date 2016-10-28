module ManageIQPerformance
  module Middlewares
    module ActiveRecordQueries

      private

      def active_record_queries_initialize
        logger = ::ManageIQPerformance::Middlewares::ActiveRecordQueries::Logger.new
        %w(sql.active_record instantiation.active_record).each do |event|
          existing_notifiers = ActiveSupport::Notifications.notifier.listeners_for(event).map do |s|
            s.instance_variable_get(:@delegate).class
          end

          unless existing_notifiers.include? logger.class
            ActiveSupport::Notifications.subscribe(event, logger)
          end
        end
      end

      def active_record_queries_start env
        ActiveRecordQueries.query_data = {
          :queries => [],
          :rows_by_class => {}
        }
      end

      def active_record_queries_finish env
        save_report env, :queries,
                    active_record_queries_short_form_data,
                    active_record_queries_long_form_data
      ensure
        ActiveRecordQueries.query_data = nil
      end

      def self.query_data
        Thread.current[:miq_perf_sql_query_data]
      end

      def self.query_data=(value)
        Thread.current[:miq_perf_sql_query_data] = value
      end

      def active_record_queries_long_form_data
        proc { ActiveRecordQueries.query_data }
      end

      def active_record_queries_short_form_data
        proc do
          {
            "queries" => ActiveRecordQueries.query_data[:total_queries],
            "rows"    => ActiveRecordQueries.query_data[:total_rows]
          }
        end
      end

      class Logger
        AR_QUERY_NOTIFIER         = "sql.active_record".freeze
        AR_INSTANTIATION_NOTIFIER = "instantiation.active_record".freeze

        def initialize
          generate_sql_filter_regexp
          set_stacktrace_cleaner
        end

        def call(name, start_time, finish_time, id, payload)
          if should_measure? && !ignore_payload?(payload)
            elapsed_time = ((finish_time.to_f - start_time.to_f) * 1000).round(1)
            if name == AR_QUERY_NOTIFIER
              # Assumed this is cached in ActiveRecord, and shouldn't count as
              # a trip to the DB
              #
              # Okay... can't do this here right now because the row counts
              # won't match the queries... If we can match up skipping the
              # instantiation with the skipping of the record_sql_query, than
              # yes, but I don't know that notifications for AR_QUERY_NOTIFIER
              # will have the "elapsed_time" for the SQL when doing the
              # AR_INSTANTIATION_NOTIFIER, and not the time to instantiate
              #
              #   return if elapsed_time.nil? || elapsed_time < 0.001

              record_sql_query payload[:sql],
                               elapsed_time,
                               binds_to_params(payload[:binds])
            elsif name == AR_INSTANTIATION_NOTIFIER
              record_instantiation elapsed_time,
                                   payload[:record_count],
                                   payload[:class_name]
            end
          end
        end

        private

        def record_sql_query sql, elapsed_time, params
          ActiveRecordQueries.query_data[:total_queries] = ActiveRecordQueries.query_data[:total_queries].to_i + 1
          query_record = {
            :sql          => sql,
            :elapsed_time => elapsed_time,
            :params       => params
          }
          query_record[:stacktrace] = sql_stacktrace if include_trace?

          ActiveRecordQueries.query_data[:queries] << query_record
        end

        def record_instantiation elapsed_time, record_count, class_name
          if record_count
            ActiveRecordQueries.query_data[:total_rows] = ActiveRecordQueries.query_data[:total_rows].to_i + record_count

            rows_for_class = ActiveRecordQueries.query_data[:rows_by_class][class_name].to_i
            ActiveRecordQueries.query_data[:rows_by_class][class_name] = rows_for_class + record_count
          end
        end

        def binds_to_params(binds)
          return if binds.nil?
          params = binds.map { |c| c.kind_of?(Array) ? [c.first, c.last] : [c.name, c.value] }
          params.map { |(n,v)| n =~ @skip_rexp ? [n, nil] : [n, v.to_s] }
        end

        def sql_stacktrace
          @stacktrace_cleaner.call Kernel.caller[2..-1]
        end

        def generate_sql_filter_regexp
          @skip_rexp = /#{Rails.application.config.filter_parameters.join("|")}/
        end

        def set_stacktrace_cleaner
          @stacktrace_cleaner = ManageIQPerformance.config.stacktrace_cleaner.new
        end

        def should_measure?
          ActiveRecordQueries.query_data
        end

        def include_trace?
          @include_trace ||= ManageIQPerformance.config.include_stack_traces?
        end

        def skip_schema_queries?
          @skip_schema_queries ||= ManageIQPerformance.config.skip_schema_queries?
        end

        # ORACLE and PG query types
        # both use nil for schema queries and non schema queries
        SCHEMA_QUERY_TYPES = ["Sequence", "Primary Key", "Primary Key Trigger", "SCHEMA"].freeze
        IGNORED_PAYLOAD    = %w[EXPLAIN CACHE].freeze

        def ignore_payload?(payload)
          payload[:exception] ||
          (skip_schema_queries? and SCHEMA_QUERY_TYPES.include?(payload[:name])) ||
          IGNORED_PAYLOAD.include?(payload[:name])
        end
      end

    end
  end
end
