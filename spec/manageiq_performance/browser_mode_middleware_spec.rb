require "manageiq_performance/browser_mode_middleware"

describe ManageIQPerformance::BrowserModeMiddleware do
  subject { described_class.new(Proc.new {}) }
  let(:performance_header) { ManageIQPerformance::Middleware::PERFORMANCE_HEADER }

  describe "#call" do
    context "with 'always_on' enabled" do
      before do
        config = ManageIQPerformance::Configuration::BROWSER_MODE_CONFIG.new(true, true)
        ManageIQPerformance.config.instance_variable_set :@browser_mode, config
      end

      it "sets the PERFORMANCE_HEADER to true" do
        env = {}
        subject.call env
        expect(env[performance_header]).to eq "true"
      end
    end

    context "with 'always_on' disabled" do
      before do
        config = ManageIQPerformance::Configuration::BROWSER_MODE_CONFIG.new(true, false)
        ManageIQPerformance.config.instance_variable_set :@browser_mode, config
      end

      it "defaults to not setting the PERFORMANCE_HEADER" do
        env = {}
        subject.call env
        expect(env[performance_header]).to be_nil
      end

      it "sets the PERFORMANCE_HEADER to true if the query string exists" do
        env = {"QUERY_STRING" => "?foo=bar&miq_performance_profile=true&bar=baz"}
        subject.call env
        expect(env[performance_header]).to eq "true"
      end
    end
  end
end
