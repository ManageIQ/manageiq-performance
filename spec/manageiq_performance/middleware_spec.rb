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

  def self.test_profile_env_for
    ManageIQPerformance.send :profile_env_for
  end

  def self.test_profile_env_for_in_block
    [1].map do
      ManageIQPerformance.send :profile_env_for
    end.first
  end
end

shared_examples "middleware functionality for" do |middleware_order|
  before do
    allow(Time).to receive(:now).and_return("1234567")
  end

  let(:basic_env) {
    {
      ManageIQPerformance::Middleware::PERFORMANCE_HEADER => true,
      "HTTP_MIQ_PERF_TIMESTAMP"                           => 1234567000000
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
      middleware_order.each do |name|
        allow(subject).to receive("#{name}_start")
      end

      middleware_order.reverse.each do |name|
        expect(subject).to receive("#{name}_finish").ordered
      end

      subject.call(basic_env)
    end

    it "calls `#finalize` on each of the middleware storages" do
      allow(subject).to receive(:performance_middleware_start)

      subject.middleware_storage.each do |storage|
        expect(storage).to receive(:finalize).ordered
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
      allow(subject).to receive(:performance_middleware_finish)

      run_profile.call
    end

    it "finishes the middleware in reverse order" do
      allow(ManageIQPerformance::Middleware).to receive(:new).and_return(middleware_instance)
      allow(subject).to receive(:performance_middleware_start)
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

    # Testing that when a name is not given, we are creating a name based on
    # the call stack.  More direct tests in `.profile_env_for` below.
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
        allow(ManageIQPerformance::Middleware).to receive(:new).and_return(middleware_instance)
        expected_env = basic_env.merge("REQUEST_PATH" => "required")
        expect(middleware_instance).to receive(:call).with(expected_env)

        eval ProfilingTestClass.test_profile_eval_script
      end
    end

    context "with the :config_changes option" do
      before(:each) do
        # Pre-require the middleware and middleware storages here incase they
        # haven't been loaded via other parts of the suite.  In most cases,
        # this will be wasteful, but the `Object.const_get` we have to do in
        # the test farther down as a return result might get executed before
        # any Middleware.new is called in the specs.
        middleware_order.each do |name|
          require "manageiq_performance/middlewares/#{name}"
        end
        ManageIQPerformance.config.middleware_storage.each do |name|
          require "manageiq_performance/middleware_storage/#{name}"
        end
      end

      # include one less middleware than what was passed into the example
      let(:config_changes) { {"middleware" => middleware_order[0..-2].map(&:to_s) } }
      let(:run_profile) do
        Proc.new do
          ManageIQPerformance.profile(:config_changes => config_changes) { work }
        end
      end

      it "loads the config changed middleware in order" do
        # Confirms that we load the reduced set of middleware that changes with
        # the config_changes
        #
        # Need to include the configured middleware storages in here as well
        # since they share the usage of `Object.const_get`, and we have to do
        # these both these prior to the `expect().to recieve` calls, otherwise
        # the spec will fail early.
        (middleware_order[0..-2].map { |name|
          constant_name = "ManageIQPerformance::Middlewares::#{name.to_s.split("_").map(&:capitalize).join}"
          constant      = Object.const_get constant_name
          [constant_name, constant]
        } + ManageIQPerformance.config.middleware_storage.map { |name|
          constant_name = "ManageIQPerformance::MiddlewareStorage::#{name.to_s.split("_").map(&:capitalize).join}"
          constant      = Object.const_get constant_name
          [constant_name, constant]
        }).each do |constant_name, constant|
          expect(Object).to receive(:const_get).with(constant_name).and_return(constant)
        end

        unused_middleware = "ManageIQPerformance::Middlewares::#{middleware_order.last.to_s.split("_").map(&:capitalize).join}"
        expect(Object).to receive(:const_get).with(unused_middleware).never

        run_profile.call
      end

      it "returns the result of the block" do
        ManageIQPerformance.profile(:config_changes => config_changes) { Thread.current[:result] = 42 }
        expect(Thread.current[:result]).to eq(42)
      end

      it "allows still setting a name for the profile block" do
        ManageIQPerformance.profile("my_name", :config_changes => config_changes) { Thread.current[:result] = 42 }
        expect(Thread.current[:result]).to eq(42)
      end
    end

    context "with :in_memory set" do
      let(:in_memory_config) { { "middleware_storage" => %w[memory] } }
      it "runs with a temporary configuration" do
        expect(ManageIQPerformance).to receive(:with_config).with(in_memory_config)
        ManageIQPerformance.profile(:in_memory => true) { work }
      end

      it "doesn't clobber other config changes" do
        config_changes = {"middleware" => [] }
        expect(ManageIQPerformance).to receive(:with_config).with(config_changes.merge in_memory_config)
        ManageIQPerformance.profile(:in_memory => true, :config_changes => config_changes) { work }
      end
    end
  end

  describe "ManageIQPerformance::profile_env_for (private)" do
    subject { ManageIQPerformance.send :profile_env_for, profile_name }

    shared_examples "sets default env fields" do
      it "sets the PERFORMANCE_HEADER to true" do
        header = ManageIQPerformance::Middleware::PERFORMANCE_HEADER
        expect(subject[header]).to be true
      end

      it "sets the HTTP_MIQ_PERF_TIMESTAMP to the current time" do
        expect(subject["HTTP_MIQ_PERF_TIMESTAMP"]).to eq(1234567000000)
      end
    end

    context "with a name given" do
      let(:profile_name) { "my_name" }
      include_examples "sets default env fields"

      it "sets the REQUEST_PATH to the name passed in" do
        expect(subject["REQUEST_PATH"]).to eq("my_name")
      end
    end

    # Tests all of the permutations that can come from the regexp parsing to
    # define name based on the backtrace line of the caller.
    context "without a name given" do
      let(:profile_name) { nil }
      # Example callstack line:
      #
      #   /spec/manageiq_performance/middleware_spec.rb:94:in `block (3 levels) in <top (required)>'
      #
      context "with a 'block (x levels) in <top (required)>' caller" do
        subject { lambda { ManageIQPerformance.send :profile_env_for }.call }
        include_examples "sets default env fields"

        it "generates a name for REQUEST_PATH" do
          expect(subject["REQUEST_PATH"]).to eq("required")
        end
      end

      # Example callstack line:
      #
      #   /spec/manageiq_performance/middleware_spec.rb:14:in `test_profiling'
      #
      context "with a '`method_name' caller" do
        subject { ProfilingTestClass.test_profile_env_for }
        include_examples "sets default env fields"

        it "generates a name for REQUEST_PATH" do
          expect(subject["REQUEST_PATH"]).to eq("test_profile_env_for")
        end
      end

      # Example callstack line:
      #
      #   /spec/manageiq_performance/middleware_spec.rb:19:in `block in test_profiling_in_block'
      #
      context "with a '`block in method_name' caller" do
        subject { ProfilingTestClass.test_profile_env_for_in_block }
        include_examples "sets default env fields"

        it "generates a name for REQUEST_PATH" do
          expect(subject["REQUEST_PATH"]).to eq("test_profile_env_for_in_block")
        end
      end

      # Example callstack line:
      #
      #   (eval):64:in `<top (required)>'
      #
      context "with an 'eval' and '`<top (required)>' caller" do
        subject { eval "ManageIQPerformance.send :profile_env_for" }
        include_examples "sets default env fields"

        it "generates a name for REQUEST_PATH" do
          expect(subject["REQUEST_PATH"]).to eq("required")
        end
      end
    end

  end

  after do
    FileUtils.rm_rf ManageIQPerformance.config.default_dir
  end
end

describe ManageIQPerformance::Middleware do
  context "with no configuration set (default)" do
    subject { described_class.new(Proc.new {}) }
    include_examples "middleware functionality for",
                     [:stackprof, :active_support_timers, :active_record_queries, :memory]
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
