require "miq_performance/middleware_storage/file"

describe MiqPerformance::MiddlewareStorage::File do
  let(:file_dir) { File.dirname(__FILE__) }
  let(:proj_dir) { File.expand_path File.join("..", "..", ".."), file_dir }

  before do
    allow(Time).to receive(:now).and_return("1234567")
  end

  describe "#initialize" do
    it "creates a suite directory" do
      described_class.new
      expected_dir = "#{proj_dir}/tmp/miq_performance/run_1234567"
      expect(File.directory? expected_dir).to be_truthy

      FileUtils.rm_rf "#{proj_dir}/tmp/miq_performance"
    end

    it "uses the default_dir config" do
      MiqPerformance.config.instance_variable_set :@default_dir,
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
      data_writer = Proc.new {|io| io.write "my middleware dataz" }
      suite_dir = "#{proj_dir}/tmp/miq_performance/run_1234567"
      filestore.record "my_result.info", &data_writer
      expect(File.read "#{suite_dir}/my_result.info").to eq "my middleware dataz"

      FileUtils.rm_rf "#{proj_dir}/tmp/miq_performance"
    end
  end
end
