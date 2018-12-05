require "manageiq_performance/reporter"

require "spec/support/spec_data/report_data/single_record"
require "spec/support/spec_data/report_data/multiple_records"

describe ManageIQPerformance::Reporter do
  let(:run_dir) { "/foo/bar" }
  subject       { described_class.new run_dir }

  describe "#collect_data" do
    let(:spec_dir)              { File.expand_path "..", File.dirname(__FILE__) }
    let(:collect_data_base_dir) { "#{spec_dir}/support/spec_data/report_data" }

    context "with one request_id" do
      let(:run_dir) { "#{collect_data_base_dir}/single_record" }

      it "compiles the data as expected" do
        expected = SpecData::ReportData::SINGLE_RECORD
        subject.send :collect_data

        expect(subject.instance_variable_get :@report_data).to eq(expected)
      end
    end

    context "with one request_id and multiple requests" do
      let(:run_dir) { "#{collect_data_base_dir}/single_record_multiple_requests" }

      it "compiles the data as expected" do
        expected = SpecData::ReportData::SINGLE_RECORD_MULTIPLE_REQUESTS
        subject.send :collect_data

        expect(subject.instance_variable_get :@report_data).to eq(expected)
      end
    end

    context "with one request_id with no query data" do
      let(:run_dir) { "#{collect_data_base_dir}/single_record_no_query_data" }

      it "compiles the data as expected" do
        expected = SpecData::ReportData::SINGLE_RECORD_NO_QUERY_DATA
        subject.send :collect_data

        expect(subject.instance_variable_get :@report_data).to eq(expected)
      end
    end

    context "with one request_id with no info data" do
      let(:run_dir) { "#{collect_data_base_dir}/single_record_no_info_data" }

      it "compiles the data as expected" do
        expected = SpecData::ReportData::SINGLE_RECORD_NO_INFO_DATA
        subject.send :collect_data

        expect(subject.instance_variable_get :@report_data).to eq(expected)
      end
    end

    context "with multiple request_ids" do
      let(:run_dir) { "#{collect_data_base_dir}/multiple_records" }

      it "compiles the data as expected" do
        expected = SpecData::ReportData::MULTIPLE_RECORDS
        subject.send :collect_data

        expect(subject.instance_variable_get :@report_data).to eq(expected)
      end
    end
  end

  describe "#print_data" do
    let(:io) { StringIO.new }
    subject  {
      described_class.new(run_dir, io)
                     .tap do |s|
                       s.instance_variable_set(:@report_data, report_data)
                     end
    }

    context "with one request_id" do
      let(:report_data) { SpecData::ReportData::SINGLE_RECORD }

      it "outputs the expected table" do
        output = <<-OUTPUT.__strip_heredoc
          /foo
          |   ms | queries | query (ms) |    rows |
          | ---: |    ---: |       ---: |    ---: |
          |  500 |      20 |         74 | 9375385 |
        OUTPUT

        subject.send :print_data
        expect(io.string).to eq(output)
      end
    end

    context "with one request_id and multiple requests" do
      let(:report_data) { SpecData::ReportData::SINGLE_RECORD_MULTIPLE_REQUESTS }

      it "outputs the expected table" do
        output = <<-OUTPUT.__strip_heredoc
          /foo
          |     ms |    queries |   query (ms) |    rows |
          |   ---: |       ---: |         ---: |    ---: |
          |    500 |         20 |         73.2 |      95 |
          | 500000 | 2000000000 | 7300000000.2 | 9375385 |
          |   5000 |         80 |         8000 |    9375 |
        OUTPUT

        subject.send :print_data
        expect(io.string).to eq(output)
      end
    end

    context "with one request_id and no query_data" do
      let(:report_data) { SpecData::ReportData::SINGLE_RECORD_NO_QUERY_DATA }

      it "outputs the expected table" do
        output = <<-OUTPUT.__strip_heredoc
          /foo
          |   ms | queries | query (ms) | rows |
          | ---: |    ---: |       ---: | ---: |
          |  500 |       0 |         74 |    0 |
        OUTPUT

        subject.send :print_data
        expect(io.string).to eq(output)
      end
    end

    context "with one request_id and no request data" do
      let(:report_data) { SpecData::ReportData::SINGLE_RECORD_NO_INFO_DATA }

      it "outputs the expected table" do
        output = <<-OUTPUT.__strip_heredoc
          /foo
          |   ms | queries | query (ms) |    rows |
          | ---: |    ---: |       ---: |    ---: |
          |    0 |      20 |       73.2 | 9375385 |
        OUTPUT

        subject.send :print_data
        expect(io.string).to eq(output)
      end
    end

    context "with multiple request_ids" do
      let(:report_data) { SpecData::ReportData::MULTIPLE_RECORDS }

      it "outputs the expected table" do
        output = <<-OUTPUT.__strip_heredoc
          /bar/baz
          |   ms | queries | query (ms) |    rows |
          | ---: |    ---: |       ---: |    ---: |
          |    0 |      20 |       73.2 | 9375385 |
          /baz/qux
          |   ms | queries | query (ms) |    rows |
          | ---: |    ---: |       ---: |    ---: |
          |  500 |      20 |         74 | 9375385 |
          /foo/bar/baz
          |     ms |    queries | query (ms) | rows |
          |   ---: |       ---: |       ---: | ---: |
          | 500000 | 2000000000 |       73.2 |  245 |
          /foo
          |     ms |    queries |   query (ms) |    rows |
          |   ---: |       ---: |         ---: |    ---: |
          |    500 |         20 |         73.2 |      95 |
          | 500000 | 2000000000 | 7300000000.2 | 9375385 |
          |   5000 |         80 |         8000 |    9375 |
        OUTPUT

        subject.send :print_data
        expect(io.string).to eq(output)
      end
    end

  end

  describe "#avg" do
    it "averages the array of ints passed in" do
      expect(subject.send :avg, [1,2,3]).to eq 2
    end

    it "returns zero if nil is passed in" do
      expect(subject.send :avg, nil).to eq 0
    end

    it "returns zero if data is an empty array" do
      expect(subject.send :avg, []).to eq 0
    end
  end
end
