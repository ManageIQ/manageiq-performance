require "manageiq_performance/middleware_storage/file"

describe ManageIQPerformance::MiddlewareStorage::File do
  let(:file_dir) { File.dirname(__FILE__) }
  let(:proj_dir) { File.expand_path File.join("..", "..", ".."), file_dir }

  before do
    allow(Time).to receive(:now).and_return("1234567")
  end

  describe "#initialize" do
    it "creates a suite directory" do
      described_class.new
      expected_dir = "#{proj_dir}/tmp/manageiq_performance/run_1234567"
      expect(File.directory? expected_dir).to be_truthy

      FileUtils.rm_rf "#{proj_dir}/tmp/manageiq_performance"
    end

    it "uses the default_dir config" do
      ManageIQPerformance.config.instance_variable_set :@default_dir,
                                                  "tmp/miqperf"
      described_class.new
      expected_dir = "#{proj_dir}/tmp/miqperf/run_1234567"
      expect(File.directory? expected_dir).to be_truthy

      FileUtils.rm_rf "#{proj_dir}/tmp/miqperf"
    end
  end

  describe "#record" do
    let(:filestore) { described_class.new }
    let(:env)       { {"REQUEST_PATH" => "/foo/bar"} }

    after(:each)    { FileUtils.rm_rf "#{proj_dir}/tmp/manageiq_performance" }

    it "writes a report to the given filename" do
      data = "my middleware dataz"
      data_writer = Proc.new { data }
      suite_dir = "#{proj_dir}/tmp/manageiq_performance/run_1234567"
      expected_filename = "foo%bar/request_1234567000000.info"

      filestore.record env, :info, nil, data_writer
      expect(File.read "#{suite_dir}/#{expected_filename}").to eq data
    end

    it "writes a report as yml if given a hash" do
      data = {"foo" => "my middleware dataz"}
      data_writer = Proc.new { data }
      suite_dir = "#{proj_dir}/tmp/manageiq_performance/run_1234567"
      expected_filename = "foo%bar/request_1234567000000.info"

      filestore.record env, :info, nil, data_writer
      expect(File.read "#{suite_dir}/#{expected_filename}").to eq data.to_yaml
    end
  end

  describe "#generic_report_filename" do
    it "builds a filename from the env['REQUEST_PATH'] variable" do
      env = {"REQUEST_PATH" => "/foo/bar/baz"}
      result = subject.send(:filename, env)
      expect(result).to eq "foo%bar%baz/request_1234567000000.data"
    end

    it "prefixes the route with 'root' if the REQUEST_PATH is '/'" do
      env = {"REQUEST_PATH" => "/"}
      result = subject.send(:filename, env)
      expect(result).to eq "root/request_1234567000000.data"
    end

    it "updates the ext if one is passed in" do
      env = {"REQUEST_PATH" => "/"}
      result = subject.send(:filename, env, :info)
      expect(result).to eq "root/request_1234567000000.info"
    end
  end

  describe "#format_path_for_filename" do
    it "returns 'root' if the request_path is '/'" do
      request_path = "/"
      result = subject.send(:format_path_for_filename, request_path)
      expect(result).to eq "root"
    end

    it "removes the leading '/' from the url" do
      request_path = "/index"
      result = subject.send(:format_path_for_filename, request_path)
      expect(result).to eq "index"
    end

    it "updates the request_path to use '%' instead of '/'" do
      request_path = "/foo/bar/baz"
      result = subject.send(:format_path_for_filename, request_path)
      expect(result).to eq "foo%bar%baz"
    end
  end

  describe "request_timestamp" do
    it "returns `Time.now` by default" do
      expect(subject.send :request_timestamp, {}).to eq 1234567000000
    end

    it "returns the value of env['HTTP_MIQ_PERF_TIMESTAMP'] if set" do
      env = {"HTTP_MIQ_PERF_TIMESTAMP" => "7654321"}
      expect(subject.send :request_timestamp, env).to eq "7654321"
    end
  end
end
