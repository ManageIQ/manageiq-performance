require "active_support"
require "active_record"
require "manageiq_performance/middleware"

middleware_defaults = ManageIQPerformance::Configuration::DEFAULTS["middleware"]

class ProfilingTestClass
  def self.test_profiling
    ManageIQPerformance.profile { 1 + 1 }
  end

  def self.test_profiling_in_block
    1.times do
      ManageIQPerformance.profile { 1 + 1 }
    end
  end

  def self.test_profile_eval_script
    <<-EOF.gsub(/^\s*/, '')
      begin
      ManageIQPerformance.profile { 1 + 1 }
      rescue
      end
    EOF
  end
end

shared_examples "middleware functionality for" do |middleware_order|
  let(:basic_env) {
    {
      ManageIQPerformance::Middleware::PERFORMANCE_HEADER => true
    }
  }

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

      subject.call(basic_env)
    end

    it "runs the middleware in order" do
      allow(subject).to receive(:performance_middleware_finish)

      middleware_order.each do |name|
        expect(subject).to receive("#{name}_start").ordered
      end

      subject.call(basic_env)
    end

    it "finishes the middleware in reverse order" do
      allow(subject).to receive(:performance_middleware_start)

      middleware_order.reverse.each do |name|
        expect(subject).to receive("#{name}_finish").ordered
      end

      subject.call(basic_env)
    end
  end

  describe "ManageIQPerformance::profile" do
    let(:work) { Proc.new { Thread.current[:result] = (1..10).to_a.inject(0, :+) } }
    let(:middleware_instance) { ManageIQPerformance::Middleware.new work }
    let(:run_profile) do
      Proc.new do
        ManageIQPerformance.profile { work }
      end
    end

    it "runs the code in the block" do
      ManageIQPerformance.profile { Thread.current[:result] = 42 }

      expect(Thread.current[:result]).to eq(42)
    end

    it "runs the middleware in order" do
      allow(ManageIQPerformance::Middleware).to receive(:new).and_return(middleware_instance)
      middleware_order.each do |name|
        expect(middleware_instance).to receive("#{name}_start").ordered
      end

      run_profile.call
    end

    it "finishes the middleware in reverse order" do
      allow(ManageIQPerformance::Middleware).to receive(:new).and_return(middleware_instance)
      middleware_order.reverse.each do |name|
        expect(middleware_instance).to receive("#{name}_finish").ordered
      end

      run_profile.call
    end

    context "with a name given" do
      it "sets the REQUEST_PATH to the name in the env" do
        allow(ManageIQPerformance::Middleware).to receive(:new).and_return(middleware_instance)
        expected_env = basic_env.merge("REQUEST_PATH" => "my_name")
        expect(middleware_instance).to receive(:call).with(expected_env)

        ManageIQPerformance.profile("my_name") { work }
      end
    end

    # Testing that when a name is given, we are creating a name based on the
    # call stack something that only has letters and underscores for the
    # generated filename.  Don't really want to create another method for this,
    # but this is some dense regexp code that is being done to generate this
    # name.
    context "without a name given" do
      # Example callstack line:
      #
      #   /spec/manageiq_performance/middleware_spec.rb:94:in `block (3 levels) in <top (required)>'
      #
      it "generates a name for REQUEST_PATH from the caller" do
        allow(ManageIQPerformance::Middleware).to receive(:new).and_return(middleware_instance)
        expected_env = basic_env.merge("REQUEST_PATH" => "required")
        expect(middleware_instance).to receive(:call).with(expected_env)

        ManageIQPerformance.profile { work }
      end

      # Example callstack line:
      #
      #   /spec/manageiq_performance/middleware_spec.rb:14:in `test_profiling'
      #
      it "name generator handles method names in call stack" do
        allow(ManageIQPerformance::Middleware).to receive(:new).and_return(middleware_instance)
        expected_env = basic_env.merge("REQUEST_PATH" => "test_profiling")
        expect(middleware_instance).to receive(:call).with(expected_env)

        ProfilingTestClass.test_profiling
      end

      # Example callstack line:
      #
      #   /spec/manageiq_performance/middleware_spec.rb:19:in `block in test_profiling_in_block'
      #
      it "name generator handles block references in call stack" do
        allow(ManageIQPerformance::Middleware).to receive(:new).and_return(middleware_instance)
        expected_env = basic_env.merge("REQUEST_PATH" => "test_profiling_in_block")
        expect(middleware_instance).to receive(:call).with(expected_env)

        ProfilingTestClass.test_profiling_in_block
      end

      # Example callstack line:
      #
      #   (eval):64:in `<top (required)>'
      #
      it "name generator handles block references in call stack" do
        puts "THIS ONE"
        allow(ManageIQPerformance::Middleware).to receive(:new).and_return(middleware_instance)
        expected_env = basic_env.merge("REQUEST_PATH" => "required")
        expect(middleware_instance).to receive(:call).with(expected_env)

        eval ProfilingTestClass.test_profile_eval_script
      end
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
