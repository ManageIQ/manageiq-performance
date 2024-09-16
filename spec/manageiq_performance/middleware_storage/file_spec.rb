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
    let(:filestore)         { described_class.new }
    let(:env)               { {"REQUEST_PATH" => "/foo/bar"} }
    let(:data_writer)       { Proc.new { data } }
    let(:suite_dir)         { "#{proj_dir}/tmp/manageiq_performance/run_1234567" }
    let(:expected_filename) { "foo%bar/request_1234567000000.info" }

    after(:each)    { FileUtils.rm_rf "#{proj_dir}/tmp/manageiq_performance" }

    context "for string data" do
      let(:data) { "my middleware dataz" }

      it "writes a basic report to the given filename" do
        filestore.record env, :info, nil, data_writer
        expect(File.read "#{suite_dir}/#{expected_filename}").to eq data
      end
    end

    context "for hash data" do
      let(:data) { {"foo" => "my middleware dataz"} }

      it "writes a report as yml if given a hash" do
        filestore.record env, :info, nil, data_writer
        expect(File.read "#{suite_dir}/#{expected_filename}").to eq data.to_yaml
      end

      context "with for queries" do
        let(:expected_filename) { "foo%bar/request_1234567000000.queries" }

        let(:data) do
          {
            :queries => [
              {
                :sql        => "SELECT * FROM some_really_long_sql_table WHERE line_length_is_vastely_greater_than_the_default_for_yaml_line_length = true",
                :stacktrace => [
                  "/foo/bar/baz.rb:5:in `baz'",
                  "/foo/bar/baz.rb:3:in `bar'",
                  "/foo/bar/baz.rb:2:in `foo'",
                  "/foo/bar/baz.rb:1:in `main'"
                ]
              }
            ]
          }
        end

        it "doesn't format query data if format_yaml_stack_traces is not set" do
          expected_to_yaml  = <<-DATA_TO_YAML.gsub(/^ {12}/, '')
            ---
            :queries:
            - :sql: SELECT * FROM some_really_long_sql_table WHERE line_length_is_vastely_greater_than_the_default_for_yaml_line_length
                = true
              :stacktrace:
              - "/foo/bar/baz.rb:5:in `baz'"
              - "/foo/bar/baz.rb:3:in `bar'"
              - "/foo/bar/baz.rb:2:in `foo'"
              - "/foo/bar/baz.rb:1:in `main'"
          DATA_TO_YAML

          filestore.record env, :queries, nil, data_writer
          expect(File.read "#{suite_dir}/#{expected_filename}").to eq expected_to_yaml
        end

        it "formats query data if format_yaml_stack_traces is set" do
          ManageIQPerformance.config.config_hash["format_yaml_stack_traces"] = true
          expected_to_yaml  = <<-DATA_TO_YAML.gsub(/^ {12}/, '')
            ---
            :queries:
            - :sql: SELECT * FROM some_really_long_sql_table WHERE line_length_is_vastely_greater_than_the_default_for_yaml_line_length = true
              :stacktrace:
              - /foo/bar/baz.rb:5:in `baz'
              - /foo/bar/baz.rb:3:in `bar'
              - /foo/bar/baz.rb:2:in `foo'
              - /foo/bar/baz.rb:1:in `main'
          DATA_TO_YAML

          filestore.record env, :queries, nil, data_writer
          expect(File.read "#{suite_dir}/#{expected_filename}").to eq expected_to_yaml
        end
      end
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

    it "maintains string if there is no leading '/'" do
      request_path = "index"
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
