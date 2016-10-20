require "yaml"

module MiqPerformance
  class Configuration
    REQUESTOR_CONFIG  = Struct.new :username,
                                   :password,
                                   :host,
                                   :read_timeout,
                                   :ignore_ssl

    DEFAULTS = {
      "default_dir" => "tmp/miq_performance",
      "requestor" => {
        "username"     => "admin",
        "password"     => "smartvm",
        "host"         => "http://localhost:3000",
        "read_timeout" => 300,
        "ignore_ssl"   => false
      },
      "middleware" => %w[
        stackprof
        active_support_timers
        active_record_queries
      ]
    }.freeze

    attr_reader :default_dir, :requestor, :middleware

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
      @config      = config
      @default_dir = config["default_dir"] || DEFAULTS["default_dir"]
      @requestor   = requestor_config config.fetch("requestor", {})
      @middleware  = config["middleware"] || DEFAULTS["middleware"]
    end

    def [](key)
      @config[key] || DEFAULTS[key]
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
        (opts["ignore_ssl"]   || defaults["ignore_ssl"])
      )
    end
  end

  def self.config
    @config ||= Configuration.load_config
  end
end
