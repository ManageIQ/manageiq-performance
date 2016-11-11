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

    it "writes a report to the given filename" do
      data_writer = Proc.new { "my middleware dataz" }
      suite_dir = "#{proj_dir}/tmp/manageiq_performance/run_1234567"
      filestore.record "my_result.info", nil, data_writer
      expect(File.read "#{suite_dir}/my_result.info").to eq "my middleware dataz"

      FileUtils.rm_rf "#{proj_dir}/tmp/manageiq_performance"
    end

    it "writes a report as yml if given a hash" do
      data = {"foo" => "my middleware dataz"}
      data_writer = Proc.new { data }
      suite_dir = "#{proj_dir}/tmp/manageiq_performance/run_1234567"
      filestore.record "my_result.info", nil, data_writer
      expect(File.read "#{suite_dir}/my_result.info").to eq data.to_yaml

      FileUtils.rm_rf "#{proj_dir}/tmp/manageiq_performance"
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
end
