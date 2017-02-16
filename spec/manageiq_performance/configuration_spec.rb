require "manageiq_performance/configuration"
require "manageiq_performance/stacktrace_cleaners/simple"
require "fileutils"

describe ManageIQPerformance::Configuration do
  let(:spec_dir) { File.expand_path "..", File.dirname(__FILE__) }
  let(:spec_tmp) { "#{spec_dir}/tmp" }
  let(:home_dir) { "#{spec_tmp}/home" }
  let(:proj_dir) { "#{home_dir}/project" }

  before(:each) do
    allow(Dir).to receive(:home).and_return(home_dir)
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
    it "defines ManageIQPerformance.config.default_dir" do
      expect(ManageIQPerformance.config.default_dir).to eq("tmp/manageiq_performance")
      expect(ManageIQPerformance.config["default_dir"]).to eq("tmp/manageiq_performance")
    end

    it "defines ManageIQPerformance.config.log_dir" do
      expect(ManageIQPerformance.config.log_dir).to eq("log")
      expect(ManageIQPerformance.config["log_dir"]).to eq("log")
    end

    it "defines ManageIQPerformance.config.skip_schema_queries?" do
      expect(ManageIQPerformance.config.skip_schema_queries?).to eq(true)
      expect(ManageIQPerformance.config["skip_schema_queries"]).to eq(true)
    end

    it "defines ManageIQPerformance.config.include_stack_traces?" do
      expect(ManageIQPerformance.config.include_stack_traces?).to eq(false)
      expect(ManageIQPerformance.config["include_stack_traces"]).to eq(false)
    end

    it "defines ManageIQPerformance.config.include_sql_queries?" do
      expect(ManageIQPerformance.config.include_sql_queries?).to eq(true)
      expect(ManageIQPerformance.config["include_sql_queries"]).to eq(true)
    end

    it "defines ManageIQPerformance.config.stacktrace_cleaner" do
      expect(ManageIQPerformance.config.stacktrace_cleaner).to eq(ManageIQPerformance::StacktraceCleaners::Simple)
      expect(ManageIQPerformance.config["stacktrace_cleaner"]).to eq("simple")
    end

    it "defines ManageIQPerformance.config.requestor.username" do
      expect(ManageIQPerformance.config.requestor.username).to eq("admin")
      expect(ManageIQPerformance.config["requestor"]["username"]).to eq("admin")
    end

    it "defines ManageIQPerformance.config.requestor.password" do
      expect(ManageIQPerformance.config.requestor.password).to eq("smartvm")
      expect(ManageIQPerformance.config["requestor"]["password"]).to eq("smartvm")
    end

    it "defines ManageIQPerformance.config.requestor.host" do
      expect(ManageIQPerformance.config.requestor.host).to eq("http://localhost:3000")
      expect(ManageIQPerformance.config["requestor"]["host"]).to eq("http://localhost:3000")
    end

    it "defines ManageIQPerformance.config.requestor.read_timeout" do
      expect(ManageIQPerformance.config.requestor.read_timeout).to eq(300)
      expect(ManageIQPerformance.config["requestor"]["read_timeout"]).to eq(300)
    end

    it "defines ManageIQPerformance.config.requestor.ignore_ssl" do
      expect(ManageIQPerformance.config.requestor.ignore_ssl).to eq(false)
      expect(ManageIQPerformance.config["requestor"]["ignore_ssl"]).to eq(false)
    end

    it "does not define ManageIQPerformance.config.requestor.requestfile_dir" do
      expect(ManageIQPerformance.config.requestor.requestfile_dir).to eq(nil)
      expect(ManageIQPerformance.config["requestor"]["requestfile_dir"]).to eq(nil)
    end

    it "defines ManageIQPerformance.config.middleware" do
      middleware = %w[stackprof active_support_timers active_record_queries]
      expect(ManageIQPerformance.config.middleware).to match_array(middleware)
      expect(ManageIQPerformance.config["middleware"]).to match_array(middleware)
    end

    it "defines ManageIQPerformance.config.middleware" do
      middleware_storage = %w[file]
      expect(ManageIQPerformance.config.middleware_storage).to match_array(middleware_storage)
      expect(ManageIQPerformance.config["middleware_storage"]).to match_array(middleware_storage)
    end

    it "defines ManageIQPerformance.config.browser_mode.enabled?" do
      expect(ManageIQPerformance.config.browser_mode.enabled?).to eq(false)
      expect(ManageIQPerformance.config["browser_mode"]["enabled"]).to eq(false)
    end

    it "defines ManageIQPerformance.config.browser_mode.always_on?" do
      expect(ManageIQPerformance.config.browser_mode.always_on?).to eq(false)
      expect(ManageIQPerformance.config["browser_mode"]["always_on"]).to eq(false)
    end
  end

  describe "loading from a yaml file" do
    let(:config) {
      <<-YAML.gsub(/^\s{8}/, "")
        ---
        default_dir: /tmp/miq_perf
        log_dir: tmp/my_log_dir
        skip_schema_queries: false
        include_stack_traces: true
        include_sql_queries: false
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
        browser_mode:
          enabled: true
          always_on: true
      YAML
    }
    before(:each) do
      File.write "#{home_dir}/.miq_performance", config
    end

    it "defines ManageIQPerformance.config.default_dir" do
      expect(ManageIQPerformance.config.default_dir).to eq("/tmp/miq_perf")
      expect(ManageIQPerformance.config["default_dir"]).to eq("/tmp/miq_perf")
    end

    it "defines ManageIQPerformance.config.log_dir" do
      expect(ManageIQPerformance.config.log_dir).to eq("tmp/my_log_dir")
      expect(ManageIQPerformance.config["log_dir"]).to eq("tmp/my_log_dir")
    end

    it "defines ManageIQPerformance.config.skip_schema_queries?" do
      expect(ManageIQPerformance.config.skip_schema_queries?).to eq(false)
      expect(ManageIQPerformance.config["skip_schema_queries"]).to eq(false)
    end

    it "defines ManageIQPerformance.config.include_stack_traces?" do
      expect(ManageIQPerformance.config.include_stack_traces?).to eq(true)
      expect(ManageIQPerformance.config["include_stack_traces"]).to eq(true)
    end

    it "defines ManageIQPerformance.config.include_sql_queries?" do
      expect(ManageIQPerformance.config.include_sql_queries?).to eq(false)
      expect(ManageIQPerformance.config["include_sql_queries"]).to eq(false)
    end

    it "defines ManageIQPerformance.config.stacktrace_cleaner" do
      expect(ManageIQPerformance.config.stacktrace_cleaner).to eq(ManageIQPerformance::StacktraceCleaners::Rails)
      expect(ManageIQPerformance.config["stacktrace_cleaner"]).to eq("rails")
    end

    it "defines ManageIQPerformance.config.requestor.username" do
      expect(ManageIQPerformance.config.requestor.username).to eq("foobar")
      expect(ManageIQPerformance.config["requestor"]["username"]).to eq("foobar")
    end

    it "defines ManageIQPerformance.config.requestor.password" do
      expect(ManageIQPerformance.config.requestor.password).to eq("p@ssw0rd")
      expect(ManageIQPerformance.config["requestor"]["password"]).to eq("p@ssw0rd")
    end

    it "defines ManageIQPerformance.config.requestor.host" do
      expect(ManageIQPerformance.config.requestor.host).to eq("http://123.45.67.89")
      expect(ManageIQPerformance.config["requestor"]["host"]).to eq("http://123.45.67.89")
    end

    it "defines ManageIQPerformance.config.requestor.read_timeout" do
      expect(ManageIQPerformance.config.requestor.read_timeout).to eq(400)
      expect(ManageIQPerformance.config["requestor"]["read_timeout"]).to eq(400)
    end

    it "defines ManageIQPerformance.config.requestor.ignore_ssl" do
      expect(ManageIQPerformance.config.requestor.ignore_ssl).to eq(true)
      expect(ManageIQPerformance.config["requestor"]["ignore_ssl"]).to eq(true)
    end

    it "defines ManageIQPerformance.config.requestor.requestfile_dir" do
      expect(ManageIQPerformance.config.requestor.requestfile_dir).to eq("config")
      expect(ManageIQPerformance.config["requestor"]["requestfile_dir"]).to eq("config")
    end

    it "defines ManageIQPerformance.config.middleware" do
      middleware = %w[active_support_timers stackprof active_record_queries]
      expect(ManageIQPerformance.config.middleware).to match_array(middleware)
      expect(ManageIQPerformance.config["middleware"]).to match_array(middleware)
    end

    it "defines ManageIQPerformance.config.middleware" do
      middleware_storage = %w[file log]
      expect(ManageIQPerformance.config.middleware_storage).to match_array(middleware_storage)
      expect(ManageIQPerformance.config["middleware_storage"]).to match_array(middleware_storage)
    end

    it "defines ManageIQPerformance.config.browser_mode.enabled?" do
      expect(ManageIQPerformance.config.browser_mode.enabled?).to eq(true)
      expect(ManageIQPerformance.config["browser_mode"]["enabled"]).to eq(true)
    end

    it "defines ManageIQPerformance.config.browser_mode.always_on?" do
      expect(ManageIQPerformance.config.browser_mode.always_on?).to eq(true)
      expect(ManageIQPerformance.config["browser_mode"]["always_on"]).to eq(true)
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
      expect(ManageIQPerformance.config.stacktrace_cleaner).to eq(ManageIQPerformance::StacktraceCleaners::Simple)
      expect(ManageIQPerformance.config["stacktrace_cleaner"]).to eq("foobar")
    end
  end
end
