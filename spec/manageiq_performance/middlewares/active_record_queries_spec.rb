require "active_record"
require "manageiq_performance/middleware"
require "manageiq_performance/middlewares/active_record_queries"

class FakeMiddleware
  include ManageIQPerformance::Middlewares::ActiveRecordQueries

  def initialize
    active_record_queries_initialize
  end
end

describe ManageIQPerformance::Middlewares::ActiveRecordQueries do
  context "with more than one instance of the middleware" do
    before(:each) do
      2.times { FakeMiddleware.new }
    end

    it "does not add duplicate ActiveSupport::Notification subscribers" do
      existing_notifiers = ActiveSupport::Notifications.notifier.listeners_for('sql.active_record').map do |s|
        s.instance_variable_get(:@delegate).class
      end

      logger_class = ::ManageIQPerformance::Middlewares::ActiveRecordQueries::Logger
      expect( existing_notifiers.select {|n| n == logger_class }.count ).to eq(1)
    end
  end
end
