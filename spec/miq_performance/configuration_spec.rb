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
    after(:each) do
      MiqPerformance.instance_variable_set :@config, nil
    end

    it "defines MiqPerformance.config.requestor.username" do
      expect(MiqPerformance.config.requestor.username).to eq("admin")
      expect(MiqPerformance.config["requestor"]["username"]).to eq("admin")
    end

    it "defines MiqPerformance.config.requestor.password" do
      expect(MiqPerformance.config.requestor.password).to eq("smartvm")
      expect(MiqPerformance.config["requestor"]["password"]).to eq("smartvm")
    end
  end

  describe "loading from a yaml file" do
    let(:config) {
      <<-YAML.gsub(/^\s{8}/, "")
        ---
        requestor:
          username: foobar
          password: p@ssw0rd
      YAML
    }
    before(:each) do
      File.write "#{home_dir}/.miq_performance", config
    end

    after(:each) do
      MiqPerformance.instance_variable_set :@config, nil
    end

    it "defines MiqPerformance.config.requestor.username" do
      expect(MiqPerformance.config.requestor.username).to eq("foobar")
      expect(MiqPerformance.config["requestor"]["username"]).to eq("foobar")
    end

    it "defines MiqPerformance.config.requestor.password" do
      expect(MiqPerformance.config.requestor.password).to eq("p@ssw0rd")
      expect(MiqPerformance.config["requestor"]["password"]).to eq("p@ssw0rd")
    end
  end
end
