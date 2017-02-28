module ManageIQPerformance
  module Middlewares
    module Memory
      private

      def memory_initialize
      end

      def memory_start(env)
        self.memory_query_data = memory_parse_data
      end

      def memory_finish(env)
        self.memory_query_data = memory_parse_data(memory_query_data)
        save_report env, :memory,
                    memory_short_form_data,
                    memory_long_form_data
      ensure
        self.memory_query_data = nil
      end

      def memory_long_form_data
        proc { memory_query_data }
      end

      def memory_short_form_data
        proc { memory_query_data }
      end

      def memory_query_data
        Thread.current[:miq_perf_request_memory_data]
      end

      def memory_query_data=(value)
        Thread.current[:miq_perf_request_memory_data] = value
      end

      def memory_include_memsize?
        ManageIQPerformance.config.include_memsize?
      end

      def memory_parse_data(old = {})
        old ||= {}
        gc_stat = GC.stat
        {
          :total_allocated_objects => gc_stat[:total_allocated_objects] - old.fetch(:total_allocated_objects, 0),
          :total_freed_objects     => gc_stat[:total_freed_objects] - old.fetch(:total_freed_objects, 0),
          # this seems duplicate. may want to shift to this from total_allocated_objects
          :total_objects           => gc_stat[:total_allocated_objects] + gc_stat[:total_freed_objects] - old.fetch(:total_objects, 0),
          :old_objects             => gc_stat[:old_objects] - old.fetch(:old_objects, 0),
          # store a 0 to make calculations easier
          :memsize_of_all          => (memory_include_memsize? ? ObjectSpace.memsize_of_all : 0) - old.fetch(:memsize_of_all, 0),
        }
      end
    end
  end
end
