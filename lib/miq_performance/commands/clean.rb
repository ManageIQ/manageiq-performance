require "miq_performance/configuration"

module MiqPerformance
  module Commands
    class Clean
      def self.help_text
        "removes unneeded runs in the run dir"
      end
    end
  end
end
