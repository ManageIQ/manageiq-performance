require "manageiq_performance/middleware_storage/log"

describe ManageIQPerformance::MiddlewareStorage::Log do
  let(:file_dir) { File.dirname(__FILE__) }
  let(:proj_dir) { File.expand_path File.join("..", "..", ".."), file_dir }
  let(:log_dir)  { "#{proj_dir}/tmp/log" }

  before do
    allow(Time).to receive(:now).and_return("1234567")

    requestor_defaults    = ManageIQPerformance::Configuration::DEFAULTS["requestor"]
    browser_mode_defaults = ManageIQPerformance::Configuration::DEFAULTS["browser_mode"]
    new_defaults = {
      "requestor"    => requestor_defaults,
      "browser_mode" => browser_mode_defaults
    }.merge "log_dir" => "tmp/log"

    stub_const("ManageIQPerformance::Configuration::DEFAULTS", new_defaults)
  end

  after do
    FileUtils.rm_rf log_dir
    Thread.current[:miq_perf_log_store_data] = nil
  end

  describe "#initialize" do
    it "creates a log file" do
      described_class.new
      expect(File.exist? "#{log_dir}/miq_performance.log").to be_truthy

      FileUtils.rm_f log_dir
    end

    it "only creates the log file if it doesn't already exist" do
      log_file = "#{log_dir}/miq_performance.log"
      log_data = "{request: '/previous/request', time: 0.1}"
      FileUtils.mkdir_p(log_dir)
      File.write log_file, log_data

      described_class.new
      expect(File.read log_file).to eq log_data
    end

    context "configured log location" do
      let(:log_dir)  { "#{proj_dir}/tmp/my_logdir" }
      it "uses the log_dir config to customize the log location" do
        ManageIQPerformance.config.instance_variable_set :@log_dir,
                                                    "tmp/my_logdir"
        described_class.new
        expected_dir = "#{proj_dir}/tmp/my_logdir"
        expect(File.exist? "#{expected_dir}/miq_performance.log").to be_truthy
      end
    end
  end

  describe "#record" do
    let(:logstore) { described_class.new }
    it "stores the middleware data for the finalize method" do
      data = {"data1" => "one", "data2" => "two"}
      data_writer = Proc.new { data }
      logstore.record "my_result.info", data_writer, nil
      expect(Thread.current[:miq_perf_log_store_data]).to eq data
    end

    it "aggregates multiple data sources" do
      data1 = {"data1" => "one", "data2" => "two"}
      data1_writer = Proc.new { data1 }
      logstore.record "my_result.info", data1_writer, nil

      data2 = {"foo" => "bar"}
      data2_writer = Proc.new { data2 }
      logstore.record "my_result.info", data2_writer, nil

      expect(Thread.current[:miq_perf_log_store_data]).to eq data1.merge(data2)
    end
  end

  describe "#finalize" do
    let(:logstore) { described_class.new }

    it "writes to the log file" do
      data1 = {"data1" => "one", "data2" => "two"}
      data1_writer = Proc.new { data1 }
      logstore.record "my_result.info", data1_writer, nil

      data2 = {"foo" => "bar"}
      data2_writer = Proc.new { data2 }
      logstore.record "my_result.info", data2_writer, nil
      logstore.finalize

      log_file = "#{proj_dir}/tmp/log/miq_performance.log"
      expect(File.read log_file).to eq "#{data1.merge(data2).to_json}\n"
    end
  end
end

