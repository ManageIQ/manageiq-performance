require "support/contexts/with_active_record"
require "manageiq_performance/middleware"
require "manageiq_performance/middlewares/active_record_queries"

class FakeQueriesMiddleware
  include ManageIQPerformance::Middlewares::ActiveRecordQueries

  def initialize
    active_record_queries_initialize
  end

  def start env
    active_record_queries_start env
  end

  def finish env
    active_record_queries_finish env
  end

  private

  def save_report(env, type, short, long)
    if env[:short]
      env[:output].puts short.call.to_json
    else
      env[:output].write YAML.dump(long.call)
    end
  end
end

describe ManageIQPerformance::Middlewares::ActiveRecordQueries do
  subject              { FakeQueriesMiddleware.new }
  let(:env)            { { :output => StringIO.new, :short => false } }
  let(:query_1)        { Book.where(:id => 1) }
  let(:query_1_result) {
    <<-QUERY.split("\n").map(&:strip).join ' '
      SELECT "books".*
      FROM "books"
      WHERE "books"."id" = ?
    QUERY
  }

  describe ".clear_memoized_logger_vars", :with_active_record do
    it "clears vars on any attached logger instances" do
      subject.start  env
      query_1.load
      subject.finish env
      described_class.clear_memoized_logger_vars

      logger = fetch_logger_for 'sql.active_record'
      expect(logger.instance_variable_defined? :@skip_schema_queries).to be false
      expect(logger.instance_variable_defined? :@include_queries).to     be false
      expect(logger.instance_variable_defined? :@include_trace).to       be false
    end
  end

  context "with more than one instance of the middleware" do
    before(:each) do
      2.times { FakeQueriesMiddleware.new }
    end

    it "does not add duplicate 'sql.active_record' subscribers" do
      existing_notifiers  = ActiveSupport::Notifications.notifier.listeners_for("sql.active_record").map do |s|
        s.instance_variable_get(:@delegate).class
      end

      logger_class = ::ManageIQPerformance::Middlewares::ActiveRecordQueries::Logger
      expect( existing_notifiers.select {|n| n == logger_class }.count ).to eq(1)
    end

    it "does not add duplicate 'instantiation.active_record' subscribers" do
      existing_notifiers = ActiveSupport::Notifications.notifier.listeners_for("instantiation.active_record").map do |s|
        s.instance_variable_get(:@delegate).class
      end

      logger_class = ::ManageIQPerformance::Middlewares::ActiveRecordQueries::Logger
      expect( existing_notifiers.select {|n| n == logger_class }.count ).to eq(1)
    end
  end

  describe "#start (private)", :with_active_record do
    before     { subject.start env }
    after      { subject.finish env }
    let(:data) { Thread.current[:miq_perf_sql_query_data] }

    it "initalizes thread data" do
      expect(data).to eq({
        :queries       => [],
        :rows_by_class => {}
      })
    end

    it "keeps track of the stored queries" do
      query_1.load

      expect(data[:queries].count).to              eq 1
      expect(data[:queries].first[:sql]).to        eq query_1_result
      expect(data[:queries].first[:params]).to     eq [["id", "1"]]
      expect(data[:queries].first[:stacktrace]).to be nil
      expect(data[:rows_by_class]["Book"]).to      eq 0
      expect(data[:total_queries]).to              eq 1
      expect(data[:total_rows]).to                 eq 0
    end

    it "skips failed queries" do
      begin
        Book.connection.execute "SELECT * FROM articles"
      rescue ActiveRecord::StatementInvalid
      end

      expect(data[:queries].count).to              eq 0
      expect(data[:rows_by_class].empty?).to       be true
      expect(data[:total_queries]).to              be nil
    end

    it "ignores EXPLAIN queries" do
      Book.connection.explain Book.all.to_sql

      expect(data[:queries].count).to              eq 0
      expect(data[:rows_by_class].empty?).to       be true
      expect(data[:total_queries]).to              be nil
    end

    it "ignores cached queries" do
      BaseClass.cache do
        query_1.load
        Book.where(:id => 1).load # query that will be cached
      end

      expect(data[:queries].count).to              eq 1
      expect(data[:queries].first[:sql]).to        eq query_1_result
      expect(data[:queries].first[:params]).to     eq [["id", "1"]]
      expect(data[:queries].first[:stacktrace]).to be nil
      expect(data[:rows_by_class]["Book"]).to      eq 0
      expect(data[:total_queries]).to              eq 1
      expect(data[:total_rows]).to                 eq 0
    end

    it "ignores SCHEMA queries" do
      BaseClass.connection.table_exists?("books")
      BaseClass.connection.table_exists?("authors")

      expect(data[:queries].count).to              eq 0
      expect(data[:rows_by_class].empty?).to       be true
      expect(data[:total_queries]).to              be nil
    end

    context "if config.skip_schema_queries? false" do
      it "includes SCHEMA queries" do
        # Get currently configured logger
        logger = fetch_logger_for 'sql.active_record'

        # Unset configured `skip_schema_queries` setting
        if logger.instance_variable_defined? :@skip_schema_queries
          logger.remove_instance_variable :@skip_schema_queries
        end

        # Run SCHEMA queries
        ManageIQPerformance.with_config('skip_schema_queries' => false) do
          BaseClass.connection.table_exists?("books")
          BaseClass.connection.table_exists?("authors")
        end

        # Clear temporary setting
        logger.remove_instance_variable :@skip_schema_queries

        expect(data[:queries].count).to            eq 2
        expect(data[:rows_by_class].empty?).to     be true
        expect(data[:total_queries]).to            be 2
      end
    end

    context "if config.include_sql_queries? is false" do
      it "doesn't include query info" do
        # Get currently configured logger
        logger = fetch_logger_for 'sql.active_record'

        # Unset configured `include_sql_queries` setting
        if logger.instance_variable_defined? :@include_queries
          logger.remove_instance_variable :@include_queries
        end

        # Run queries
        ManageIQPerformance.with_config('include_sql_queries' => false) do
          query_1.load
        end

        # Clear temporary setting
        logger.remove_instance_variable :@include_queries

        expect(data[:queries].count).to            eq 0
        expect(data[:rows_by_class]["Book"]).to    eq 0
        expect(data[:total_queries]).to            eq 1
        expect(data[:total_rows]).to               eq 0
      end
    end

    context "if config.include_stack_traces? is true" do
      it "includes stacktraces of sql queries" do
        # Get currently configured logger
        logger = fetch_logger_for 'sql.active_record'

        # Unset configured `include_stack_traces` setting
        if logger.instance_variable_defined? :@include_trace
          logger.remove_instance_variable :@include_trace
        end

        # Run queries
        ManageIQPerformance.with_config('include_stack_traces' => true) do
          query_1.load
        end

        # Clear temporary setting
        logger.remove_instance_variable :@include_trace

        actual_stacktrace = data[:queries].first[:stacktrace]
        this_file_name    = __FILE__.sub(/.*\/(spec.*)/, '\1')
        expect(actual_stacktrace.first).to include this_file_name
      end
    end
  end

  describe "#finish (private)", :with_active_record do
    before do
      subject.start env
      query_1.load
      subject.finish env
    end

    it "saves the report" do
      data = YAML.load env[:output].tap(&:rewind)

      expect(data[:queries].count).to              eq 1
      expect(data[:queries].first[:sql]).to        eq query_1_result
      expect(data[:queries].first[:params]).to     eq [["id", "1"]]
      expect(data[:queries].first[:stacktrace]).to be nil
      expect(data[:rows_by_class]["Book"]).to      eq 0
      expect(data[:total_queries]).to              eq 1
      expect(data[:total_rows]).to                 eq 0
    end

    it "clears Thread.current[:miq_perf_sql_query_data]" do
      expect(Thread.current[:miq_perf_sql_query_data]).to be nil
    end

    context "with the short form configured in the env" do
      let(:env) { { :output => StringIO.new, :short => true } }

      it "saves the report with the short form data" do
        data = JSON.parse env[:output].tap(&:rewind).each_line.first

        expect(data['queries']).to eq 1
        expect(data['rows']).to    eq 0
      end
    end
  end

  def fetch_logger_for event
    ActiveSupport::Notifications.notifier.listeners_for(event).detect do |l|
      l.instance_variable_get(:@delegate).is_a? described_class::Logger
    end.instance_variable_get(:@delegate)
  end
end
