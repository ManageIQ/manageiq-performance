require "manageiq_performance/configuration"
require "manageiq_performance/stacktrace_cleaners/simple"
require "fileutils"

# Few things to know about this spec file:
#
#   * The spec helper has a callback in it to clear out the global "config"
#   after each test (needed in other places)
#   * We use a fake home dir and project dir to avoid loading a user's actual
#   config when running tests on a developer's machine

shared_examples "the default config" do |config_options={}|
  default_config_hash = {
    ["default_dir"]                  => "tmp/manageiq_performance",
    ["log_dir"]                      => "log",
    ["skip_schema_queries?"]         => true,
    ["include_stack_traces?"]        => false,
    ["format_yaml_stack_traces?"]         => false,
    ["include_sql_queries?"]         => true,
    ["include_memsize?"]             => false,
    ["stacktrace_cleaner"]           => ManageIQPerformance::StacktraceCleaners::Simple,
    ["requestor", "username"]        => "admin",
    ["requestor", "password"]        => "smartvm",
    ["requestor", "host"]            => "http://localhost:3000",
    ["requestor", "read_timeout"]    => 300,
    ["requestor", "ignore_ssl"]      => false,
    ["requestor", "requestfile_dir"] => nil,
    ["middleware"]                   => %w[stackprof active_support_timers active_record_queries memory],
    ["middleware_storage"]           => %w[file],
    ["monitor_queue?"]               => false,
    ["browser_mode", "enabled?"]     => false,
    ["browser_mode", "always_on?"]   => false,
    ["browser_mode", "whitelist"]    => nil,
  }

  # Convert a default value to what is expected from a hash config.  Basically
  # transforms things that would eventually be converted from the yaml config
  # to represent someting more complext like a class from the library, but
  # mostly just returns the same value that was passed in
  def expected_config_hash_value(expected)
    simple_config_value_classes = [Array, String, Numeric, TrueClass, FalseClass, NilClass]
    case expected
    when *simple_config_value_classes then expected
    else
      if expected.name.include?("ManageIQPerformance")
        expected.name.split("::").last.downcase
      else
        expected
      end
    end
  end

  def extract_config_method_value(config_keys)
    config_keys.inject(ManageIQPerformance.config) do |result, key|
      result.send key
    end
  end

  def extract_config_hash_value(config_keys)
    config_keys.inject(ManageIQPerformance.config) do |result, key|
      result[key.sub(/\?$/, '')]
    end
  end

  exclude_keys = config_options[:without] || []
  default_config_hash.reject { |key,_| exclude_keys.include?(key) }.each do |config_keys, expected|
    it "defining ManageIQPerformance.config.#{config_keys.join('.')}" do
      expect(extract_config_method_value(config_keys)).to eq expected
      expect(extract_config_hash_value(config_keys)).to eq expected_config_hash_value expected
    end
  end

  default_config_hash.select { |key,_| exclude_keys.include?(key) }.each do |config_keys, expected|
    it "does not use the default for ManageIQPerformance.config.#{config_keys.join('.')}" do
      expect(extract_config_method_value(config_keys)).to_not eq expected
      expect(extract_config_hash_value(config_keys)).to_not eq expected_config_hash_value expected
    end
  end
end

describe ManageIQPerformance::Configuration do
  let(:spec_dir) { File.expand_path "..", File.dirname(__FILE__) }
  let(:spec_tmp) { "#{spec_dir}/tmp" }
  let(:home_dir) { "#{spec_tmp}/home" }
  let(:proj_dir) { "#{home_dir}/project" }

  before(:each) do
    allow(Dir).to receive(:home).and_return(home_dir)
    described_class.instance_variable_set :@config_file_location, nil
  end

  around(:example) do |example|
    FileUtils.mkdir_p proj_dir
    Dir.chdir(proj_dir) { example.run }
    FileUtils.rm_rf spec_tmp
  end

  after(:each) do
    described_class.instance_variable_set :@config_file_location, nil
  end

  describe "::config_file_location" do
    subject { described_class }

    it "returns nil if no file exists" do
      expect(subject.config_file_location).to be_nil
    end

    context "with a local config" do
      it "returns the full file path if it exists" do
        config_filename = "#{proj_dir}/.miq_performance"
        FileUtils.touch config_filename
        expect(subject.config_file_location).to eq config_filename
      end

      it "allows the .cnf extension" do
        config_filename = "#{proj_dir}/.miq_performance.cnf"
        FileUtils.touch config_filename
        expect(subject.config_file_location).to eq config_filename
      end

      it "allows the .conf extension" do
        config_filename = "#{proj_dir}/.miq_performance.cnf"
        FileUtils.touch config_filename
        expect(subject.config_file_location).to eq config_filename
      end

      it "allows the .yml extension" do
        config_filename = "#{proj_dir}/.miq_performance.yml"
        FileUtils.touch config_filename
        expect(subject.config_file_location).to eq config_filename
      end
    end

    context "with a local config" do
      it "returns the full file path if it exists" do
        config_filename = "#{home_dir}/.miq_performance"
        FileUtils.touch config_filename
        expect(subject.config_file_location).to eq config_filename
      end

      it "allows the .cnf extension" do
        config_filename = "#{home_dir}/.miq_performance.cnf"
        FileUtils.touch config_filename
        expect(subject.config_file_location).to eq config_filename
      end

      it "allows the .conf extension" do
        config_filename = "#{home_dir}/.miq_performance.cnf"
        FileUtils.touch config_filename
        expect(subject.config_file_location).to eq config_filename
      end

      it "allows the .yml extension" do
        config_filename = "#{home_dir}/.miq_performance.yml"
        FileUtils.touch config_filename
        expect(subject.config_file_location).to eq config_filename
      end
    end
  end

  describe "default config" do
    it_should_behave_like "the default config"
  end

  describe "loading from a yaml file" do
    let(:config) {
      <<-YAML.gsub(/^\s{8}/, "")
        ---
        default_dir: /tmp/miq_perf
        log_dir: tmp/my_log_dir
        skip_schema_queries: false
        include_stack_traces: true
        format_yaml_stack_traces: true
        include_sql_queries: false
        include_memsize: true
        stacktrace_cleaner: rails
        requestor:
          username: foobar
          password: p@ssw0rd
          host: http://123.45.67.89
          read_timeout: 400
          ignore_ssl: true
          requestfile_dir: config
        middleware:
          - active_support_timers
          - stackprof
          - active_record_queries
        middleware_storage:
          - file
          - log
        monitor_queue: true
        browser_mode:
          enabled: true
          always_on: true
          whitelist:
            - /vm_infra/explorer
            - /vm_infra/x_button
            - /dashboard/show
      YAML
    }
    before(:each) do
      File.write "#{home_dir}/.miq_performance", config
    end

    it "defines ManageIQPerformance.config.default_dir" do
      expect(ManageIQPerformance.config.default_dir).to eq "/tmp/miq_perf"
      expect(ManageIQPerformance.config["default_dir"]).to eq "/tmp/miq_perf"
    end

    it "defines ManageIQPerformance.config.log_dir" do
      expect(ManageIQPerformance.config.log_dir).to eq "tmp/my_log_dir"
      expect(ManageIQPerformance.config["log_dir"]).to eq "tmp/my_log_dir"
    end

    it "defines ManageIQPerformance.config.skip_schema_queries?" do
      expect(ManageIQPerformance.config.skip_schema_queries?).to eq false
      expect(ManageIQPerformance.config["skip_schema_queries"]).to eq false
    end

    it "defines ManageIQPerformance.config.include_stack_traces?" do
      expect(ManageIQPerformance.config.include_stack_traces?).to eq true
      expect(ManageIQPerformance.config["include_stack_traces"]).to eq true
    end

    it "defines ManageIQPerformance.config.format_yaml_stack_traces?" do
      expect(ManageIQPerformance.config.format_yaml_stack_traces?).to eq true
      expect(ManageIQPerformance.config["format_yaml_stack_traces"]).to eq true
    end

    it "defines ManageIQPerformance.config.include_sql_queries?" do
      expect(ManageIQPerformance.config.include_sql_queries?).to eq false
      expect(ManageIQPerformance.config["include_sql_queries"]).to eq false
    end

    it "defines ManageIQPerformance.config.include_memsize?" do
      expect(ManageIQPerformance.config.include_memsize?).to eq true
      expect(ManageIQPerformance.config["include_memsize"]).to eq true
    end

    it "defines ManageIQPerformance.config.stacktrace_cleaner" do
      expect(ManageIQPerformance.config.stacktrace_cleaner).to eq ManageIQPerformance::StacktraceCleaners::Rails
      expect(ManageIQPerformance.config["stacktrace_cleaner"]).to eq "rails"
    end

    it "defines ManageIQPerformance.config.requestor.username" do
      expect(ManageIQPerformance.config.requestor.username).to eq "foobar"
      expect(ManageIQPerformance.config["requestor"]["username"]).to eq "foobar"
    end

    it "defines ManageIQPerformance.config.requestor.password" do
      expect(ManageIQPerformance.config.requestor.password).to eq "p@ssw0rd"
      expect(ManageIQPerformance.config["requestor"]["password"]).to eq "p@ssw0rd"
    end

    it "defines ManageIQPerformance.config.requestor.host" do
      expect(ManageIQPerformance.config.requestor.host).to eq "http://123.45.67.89"
      expect(ManageIQPerformance.config["requestor"]["host"]).to eq "http://123.45.67.89"
    end

    it "defines ManageIQPerformance.config.requestor.read_timeout" do
      expect(ManageIQPerformance.config.requestor.read_timeout).to eq 400
      expect(ManageIQPerformance.config["requestor"]["read_timeout"]).to eq 400
    end

    it "defines ManageIQPerformance.config.requestor.ignore_ssl" do
      expect(ManageIQPerformance.config.requestor.ignore_ssl).to eq true
      expect(ManageIQPerformance.config["requestor"]["ignore_ssl"]).to eq true
    end

    it "defines ManageIQPerformance.config.requestor.requestfile_dir" do
      expect(ManageIQPerformance.config.requestor.requestfile_dir).to eq "config"
      expect(ManageIQPerformance.config["requestor"]["requestfile_dir"]).to eq "config"
    end

    it "defines ManageIQPerformance.config.middleware" do
      middleware = %w[active_support_timers stackprof active_record_queries]
      expect(ManageIQPerformance.config.middleware).to match_array middleware
      expect(ManageIQPerformance.config["middleware"]).to match_array middleware
    end

    it "defines ManageIQPerformance.config.middleware" do
      middleware_storage = %w[file log]
      expect(ManageIQPerformance.config.middleware_storage).to eq middleware_storage
      expect(ManageIQPerformance.config["middleware_storage"]).to eq middleware_storage
    end

    it "defines ManageIQPerformance.config.monitor_queue?" do
      expect(ManageIQPerformance.config.monitor_queue?).to eq true
      expect(ManageIQPerformance.config["monitor_queue"]).to eq true
    end

    it "defines ManageIQPerformance.config.browser_mode.enabled?" do
      expect(ManageIQPerformance.config.browser_mode.enabled?).to eq true
      expect(ManageIQPerformance.config["browser_mode"]["enabled"]).to eq true
    end

    it "defines ManageIQPerformance.config.browser_mode.always_on?" do
      expect(ManageIQPerformance.config.browser_mode.always_on?).to eq true
      expect(ManageIQPerformance.config["browser_mode"]["always_on"]).to eq true
    end

    it "defines ManageIQPerformance.config.browser_mode.whitelist?" do
      expect(ManageIQPerformance.config.browser_mode.whitelist?).to eq true
    end

    it "defines ManageIQPerformance.config.browser_mode.whitelist" do
      expected = %w[
        /vm_infra/explorer
        /vm_infra/x_button
        /dashboard/show
      ]
      expect(ManageIQPerformance.config.browser_mode.whitelist).to eq expected
      expect(ManageIQPerformance.config["browser_mode"]["whitelist"]).to eq expected
    end
  end

  describe "loading from a poorly configured yaml file" do
    let(:config) {
      <<-YAML.gsub(/^\s{8}/, "")
        ---
        stacktrace_cleaner: foobar
      YAML
    }
    before(:each) do
      File.write "#{home_dir}/.miq_performance", config
    end

    it "uses the simple StacktraceCleaner by default" do
      expect(ManageIQPerformance.config.stacktrace_cleaner).to eq ManageIQPerformance::StacktraceCleaners::Simple
      expect(ManageIQPerformance.config["stacktrace_cleaner"]).to eq "foobar"
    end
  end

  describe "reassigning the config" do
    before(:each) do
      ManageIQPerformance.config = { "default_dir" => "foo/bar/baz" }
    end

    it_behaves_like "the default config", :without => [["default_dir"]]

    it "sets the config to now point to the default dir changes" do
      expect(ManageIQPerformance.config.default_dir).to eq "foo/bar/baz"
      expect(ManageIQPerformance.config["default_dir"]).to eq "foo/bar/baz"
    end
  end

  describe "with a temporary set of config changes" do
    let(:config_changes) { { "default_dir" => "foo/bar/baz" } }

    it "only makes the changes to default_dir during the duration of the block" do
      expect(ManageIQPerformance.config.default_dir).to eq "tmp/manageiq_performance"
      expect(ManageIQPerformance.config["default_dir"]).to eq "tmp/manageiq_performance"

      ManageIQPerformance.with_config(config_changes) do
        expect(ManageIQPerformance.config.default_dir).to eq "foo/bar/baz"
        expect(ManageIQPerformance.config["default_dir"]).to eq "foo/bar/baz"
      end

      expect(ManageIQPerformance.config.default_dir).to eq "tmp/manageiq_performance"
      expect(ManageIQPerformance.config["default_dir"]).to eq "tmp/manageiq_performance"
    end

    it "inherits values set in the previous config" do
      ManageIQPerformance.config = { "include_sql_queries" => false }

      expect(ManageIQPerformance.config.include_sql_queries?).to eq false
      expect(ManageIQPerformance.config["include_sql_queries"]).to eq false
      expect(ManageIQPerformance.config.default_dir).to eq "tmp/manageiq_performance"
      expect(ManageIQPerformance.config["default_dir"]).to eq "tmp/manageiq_performance"

      ManageIQPerformance.with_config(config_changes) do
        expect(ManageIQPerformance.config.include_sql_queries?).to eq false
        expect(ManageIQPerformance.config["include_sql_queries"]).to eq false
        expect(ManageIQPerformance.config.default_dir).to eq "foo/bar/baz"
        expect(ManageIQPerformance.config["default_dir"]).to eq "foo/bar/baz"
      end

      expect(ManageIQPerformance.config.default_dir).to eq "tmp/manageiq_performance"
      expect(ManageIQPerformance.config["default_dir"]).to eq "tmp/manageiq_performance"
    end

    it "returns the result of the block" do
      result = ManageIQPerformance.with_config(config_changes) do
        ManageIQPerformance.config.default_dir
      end
      expect(result).to eq config_changes["default_dir"]
    end
  end
end
