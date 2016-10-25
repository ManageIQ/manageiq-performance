module MiqPerformance
  module Commands
    class Help
      def self.help
        help_text = ["Usage: #{File.basename $0} [options] args...", ""]

        command_files = Dir["#{File.dirname __FILE__}/*"].sort
        ljust_length  = command_files.map {|f| File.basename(f).length}.max
        command_files.each do |command_file|
          begin
            require command_file

            cmd   = File.basename(command_file, ".*")
            klass = MiqPerformance::Commands.const_get(cmd.capitalize)

            help_text << "    #{cmd.ljust ljust_length} #{klass.help_text}"
          rescue NameError
            # The class isn't defined, so move on
            #
            # This can be caused by a dependent gem not being installed, so
            # allow the rest of the commands to still function that don't
            # require that dependency.
          end
        end

        puts help_text.join("\n")
      end

      def self.help_text
        "show this help or the help for a subcommand"
      end
    end

    def self.help
      Help.help
    end
  end
end
