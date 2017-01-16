require "active_support"
require "active_record"
require "manageiq_performance/middleware"

middleware_defaults = ManageIQPerformance::Configuration::DEFAULTS["middleware"]

shared_examples "middleware functionality for" do |middleware_order|
  middleware_order.each do |name|
    it "loads #{name} middleware" do
      expect(subject.private_methods.include? "#{name}_start".to_sym).to  be true
      expect(subject.private_methods.include? "#{name}_finish".to_sym).to be true
      expect(subject.private_methods.include? "#{name}_initialize".to_sym).to be true
    end
  end

  (middleware_defaults - middleware_order.map(&:to_s)).each do |name|
    it "does not load #{name} middleware" do
      my_subject = described_class.new(Proc.new {})
      expect(my_subject.private_methods.include? "#{name}_start".to_sym).to  be false
      expect(my_subject.private_methods.include? "#{name}_finish".to_sym).to be false
      expect(my_subject.private_methods.include? "#{name}_initialize".to_sym).to be false
    end
  end

  describe "#call" do
    it "skips the middleware if the proper header is not present" do
      expect(subject).to receive(:performance_middleware_start).never
      expect(subject).to receive(:performance_middleware_finish).never

      subject.call({})
    end

    it "runs the middleware if the proper header is present" do
      expect(subject).to receive(:performance_middleware_start).once
      expect(subject).to receive(:performance_middleware_finish).once

      subject.call({ ManageIQPerformance::Middleware::PERFORMANCE_HEADER => true})
    end

    it "runs the middleware in order" do
      allow(subject).to receive(:performance_middleware_finish)

      middleware_order.each do |name|
        expect(subject).to receive("#{name}_start").ordered
      end

      subject.call({ ManageIQPerformance::Middleware::PERFORMANCE_HEADER => true})
    end

    it "finishes the middleware in reverse order" do
      allow(subject).to receive(:performance_middleware_start)

      middleware_order.reverse.each do |name|
        expect(subject).to receive("#{name}_finish").ordered
      end

      subject.call({ ManageIQPerformance::Middleware::PERFORMANCE_HEADER => true})
    end
  end

  after do
    FileUtils.rm_r ManageIQPerformance.config.default_dir
  end
end

describe ManageIQPerformance::Middleware do
  context "with no configuration set (default)" do
    subject { described_class.new(Proc.new {}) }
    include_examples "middleware functionality for",
                     [:stackprof, :active_support_timers, :active_record_queries]
  end

  context "with only stackprof and active_record_queries middlewares" do
    subject { described_class.new(Proc.new {}) }
    before do
      ManageIQPerformance.config.instance_variable_set :@middleware, %w[stackprof active_record_queries]
    end

    include_examples "middleware functionality for",
                     [:stackprof, :active_record_queries]
  end
end
