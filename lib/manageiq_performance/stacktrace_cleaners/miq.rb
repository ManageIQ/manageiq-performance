require "english"

module ManageIQPerformance
  module StacktraceCleaners
    class Miq
      # Expanded cleaner that will:
      #
      #   - include the current rails directory
      #   - any bundled gems that are prefixed with `manageiq`
      #
      def initialize
        @our_gem_prefix   = "manageiq"
        @our_gems_bundled = File.join Bundler.home, "gems", @our_gem_prefix
        @our_gems_local   = ::Rails.root.join("..", @our_gem_prefix).to_s
        @app_root         = File.join ::Rails.root, ""

        @regexp = /^(?:#{@app_root}|#{@our_gems_bundled}|#{@our_gems_local})/
      end

      def call(stacktrace=Kernel.caller)
        # In a single* loop interation we:
        #
        #   - .gsub the line strip any gem dir info
        #   - If there was a match, it is something we are looking for
        #
        # If there was no $MATCH in the .gsub, then it gets dropped in the
        # .compact call
        stacktrace.reduce([]) do |trace, line|
          sub = line.gsub @regexp, @app_root => "",
                                   @our_gems_bundled => @our_gem_prefix,
                                   @our_gems_local   => @our_gem_prefix
          trace << sub if $MATCH
          trace
        end
      end
    end
  end
end
