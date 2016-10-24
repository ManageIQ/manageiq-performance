require "miq_performance/configuration"
require "fileutils"

describe MiqPerformance::Configuration do
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
    it "defines MiqPerformance.config.default_dir" do
      expect(MiqPerformance.config.default_dir).to eq("tmp/miq_performance")
      expect(MiqPerformance.config["default_dir"]).to eq("tmp/miq_performance")
    end

    it "defines MiqPerformance.config.skip_schema_queries?" do
      expect(MiqPerformance.config.skip_schema_queries?).to eq(true)
      expect(MiqPerformance.config["skip_schema_queries"]).to eq(true)
    end

    it "defines MiqPerformance.config.include_stack_traces?" do
      expect(MiqPerformance.config.include_stack_traces?).to eq(false)
      expect(MiqPerformance.config["include_stack_traces"]).to eq(false)
    end

    it "defines MiqPerformance.config.requestor.username" do
      expect(MiqPerformance.config.requestor.username).to eq("admin")
      expect(MiqPerformance.config["requestor"]["username"]).to eq("admin")
    end

    it "defines MiqPerformance.config.requestor.password" do
      expect(MiqPerformance.config.requestor.password).to eq("smartvm")
      expect(MiqPerformance.config["requestor"]["password"]).to eq("smartvm")
    end

    it "defines MiqPerformance.config.requestor.host" do
      expect(MiqPerformance.config.requestor.host).to eq("http://localhost:3000")
      expect(MiqPerformance.config["requestor"]["host"]).to eq("http://localhost:3000")
    end

    it "defines MiqPerformance.config.requestor.read_timeout" do
      expect(MiqPerformance.config.requestor.read_timeout).to eq(300)
      expect(MiqPerformance.config["requestor"]["read_timeout"]).to eq(300)
    end

    it "defines MiqPerformance.config.requestor.ignore_ssl" do
      expect(MiqPerformance.config.requestor.ignore_ssl).to eq(false)
      expect(MiqPerformance.config["requestor"]["ignore_ssl"]).to eq(false)
    end

    it "does not define MiqPerformance.config.requestor.requestfile_dir" do
      expect(MiqPerformance.config.requestor.requestfile_dir).to eq(nil)
      expect(MiqPerformance.config["requestor"]["requestfile_dir"]).to eq(nil)
    end

    it "defines MiqPerformance.config.middleware" do
      middleware = %w[stackprof active_support_timers active_record_queries]
      expect(MiqPerformance.config.middleware).to match_array(middleware)
      expect(MiqPerformance.config["middleware"]).to match_array(middleware)
    end
  end

  describe "loading from a yaml file" do
    let(:config) {
      <<-YAML.gsub(/^\s{8}/, "")
        ---
        default_dir: /tmp/miq_perf
        skip_schema_queries: false
        include_stack_traces: true
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
      YAML
    }
    before(:each) do
      File.write "#{home_dir}/.miq_performance", config
    end

    it "defines MiqPerformance.config.default_dir" do
      expect(MiqPerformance.config.default_dir).to eq("/tmp/miq_perf")
      expect(MiqPerformance.config["default_dir"]).to eq("/tmp/miq_perf")
    end

    it "defines MiqPerformance.config.skip_schema_queries?" do
      expect(MiqPerformance.config.skip_schema_queries?).to eq(false)
      expect(MiqPerformance.config["skip_schema_queries"]).to eq(false)
    end

    it "defines MiqPerformance.config.include_stack_traces?" do
      expect(MiqPerformance.config.include_stack_traces?).to eq(true)
      expect(MiqPerformance.config["include_stack_traces"]).to eq(true)
    end

    it "defines MiqPerformance.config.requestor.username" do
      expect(MiqPerformance.config.requestor.username).to eq("foobar")
      expect(MiqPerformance.config["requestor"]["username"]).to eq("foobar")
    end

    it "defines MiqPerformance.config.requestor.password" do
      expect(MiqPerformance.config.requestor.password).to eq("p@ssw0rd")
      expect(MiqPerformance.config["requestor"]["password"]).to eq("p@ssw0rd")
    end

    it "defines MiqPerformance.config.requestor.host" do
      expect(MiqPerformance.config.requestor.host).to eq("http://123.45.67.89")
      expect(MiqPerformance.config["requestor"]["host"]).to eq("http://123.45.67.89")
    end

    it "defines MiqPerformance.config.requestor.read_timeout" do
      expect(MiqPerformance.config.requestor.read_timeout).to eq(400)
      expect(MiqPerformance.config["requestor"]["read_timeout"]).to eq(400)
    end

    it "defines MiqPerformance.config.requestor.ignore_ssl" do
      expect(MiqPerformance.config.requestor.ignore_ssl).to eq(true)
      expect(MiqPerformance.config["requestor"]["ignore_ssl"]).to eq(true)
    end

    it "defines MiqPerformance.config.requestor.requestfile_dir" do
      expect(MiqPerformance.config.requestor.requestfile_dir).to eq("config")
      expect(MiqPerformance.config["requestor"]["requestfile_dir"]).to eq("config")
    end

    it "defines MiqPerformance.config.middleware" do
      middleware = %w[active_support_timers stackprof active_record_queries]
      expect(MiqPerformance.config.middleware).to match_array(middleware)
      expect(MiqPerformance.config["middleware"]).to match_array(middleware)
    end
  end
end
