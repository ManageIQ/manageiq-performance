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
    # no-op for now
  end
end

describe ManageIQPerformance::Middlewares::ActiveRecordQueries do
  subject              { FakeQueriesMiddleware.new }
  let(:env)            { {} }
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

  def fetch_logger_for event
    ActiveSupport::Notifications.notifier.listeners_for(event).detect do |l|
      l.instance_variable_get(:@delegate).is_a? described_class::Logger
    end.instance_variable_get(:@delegate)
  end
end
