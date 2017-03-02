require "yaml"

module ManageIQPerformance
  class Configuration
    REQUESTOR_CONFIG     = Struct.new :username,
                                      :password,
                                      :host,
                                      :read_timeout,
                                      :ignore_ssl,
                                      :requestfile_dir

    BROWSER_MODE_CONFIG  = Struct.new :enabled?,
                                      :always_on?

    DEFAULTS = {
      "default_dir"          => "tmp/manageiq_performance",
      "log_dir"              => "log",
      "skip_schema_queries"  => true,
      "include_stack_traces" => false,
      "include_sql_queries"  => true,
      "stacktrace_cleaner"   => "simple",
      "requestor"            => {
        "username"     => "admin",
        "password"     => "smartvm",
        "host"         => "http://localhost:3000",
        "read_timeout" => 300,
        "ignore_ssl"   => false
      },
      # also have middleware: stackprof
      "middleware"           => %w[
        active_support_timers
        active_record_queries
      ],
      "middleware_storage"   => %w[file],
      "browser_mode"  => {
        "enabled"   => false,
        "always_on" => false
      }
    }.freeze

    attr_reader :default_dir, :log_dir, :requestor,
                :middleware, :middleware_storage,
                :browser_mode

    def self.load_config
      new load_config_file
    end

    # Determine the most usable config file available on the file system.
    # Allows the use of no ext or `.cnf`, `.conf`, or `.yml` for the file
    # extensions.
    def self.config_file_location
      @config_file_location ||=
        ".miq_performance #{Dir.home}/.miq_performance"
          .split.flat_map { |filepath|
            ["", ".cnf", ".conf", ".yml"].map { |ext|
              File.expand_path "#{filepath}#{ext}"
            }
          }.detect { |filepath|
            File.exist? filepath
          }
    end

    def initialize(config={})
      @config             = config
      @default_dir        = self["default_dir"]
      @log_dir            = self["log_dir"]
      @requestor          = requestor_config config.fetch("requestor", {})
      @middleware         = self["middleware"]
      @middleware_storage = self["middleware_storage"]
      @browser_mode       = browser_mode_config config.fetch("browser_mode", {})
    end

    def [](key)
      @config.fetch key, DEFAULTS[key]
    end

    def skip_schema_queries?
      self["skip_schema_queries"]
    end

    def include_sql_queries?
      self["include_sql_queries"]
    end

    def include_stack_traces?
      self["include_stack_traces"]
    end

    def stacktrace_cleaner
      @stacktrace_cleaner ||=
        begin
          cleaner = self["stacktrace_cleaner"]

          require "manageiq_performance/stacktrace_cleaners/#{cleaner}"
          ManageIQPerformance::StacktraceCleaners.const_get(cleaner.capitalize)
        rescue LoadError
          require "manageiq_performance/stacktrace_cleaners/simple"
          ManageIQPerformance::StacktraceCleaners::Simple
        end
    end

    private

    def self.load_config_file
      load_from_yaml || {}
    end
    private_class_method :load_config_file

    def self.load_from_yaml
      YAML.load_file config_file_location
    rescue
      nil
    end
    private_class_method :load_from_yaml

    def requestor_config(opts={})
      defaults = DEFAULTS["requestor"]
      REQUESTOR_CONFIG.new(
        (opts["username"]     || defaults["username"]),
        (opts["password"]     || defaults["password"]),
        (opts["host"]         || defaults["host"]),
        (opts["read_timeout"] || defaults["read_timeout"]),
        (opts["ignore_ssl"]   || defaults["ignore_ssl"]),
        (opts["requestfile_dir"])
      )
    end

    def browser_mode_config(opts={})
      defaults = DEFAULTS["browser_mode"]
      BROWSER_MODE_CONFIG.new(
        (opts["enabled"]   || defaults["enabled"]),
        (opts["always_on"] || defaults["always_on"])
      )
    end
  end

  def self.config
    @config ||= Configuration.load_config
  end
end
