require "manageiq_performance/middleware_storage/memory"

describe ManageIQPerformance::MiddlewareStorage::Memory do
  let(:env)         { {} }
  let(:data)        { { :sql_queries => %w[Query1 Query2] } }
  let(:data_writer) { Proc.new { data } }

  describe "#initialize" do
    # Make sure the subject is initialized in each spec to reset last_run
    before(:each) { subject }

    it "setups a 'profile_captures' object" do
      expect(subject.profile_captures).to eq []
    end

    it "resets the ManageIQPerformance.last_run" do
      expect(ManageIQPerformance.last_run).to eq nil
    end
  end

  describe "#record" do
    it "stores the data from the record in a nested hash" do
      subject.record env, :sql, nil, data_writer
      expect(subject.current_run[:sql]).to eq data
    end
  end

  describe "finalize" do
    let(:data2) { { :sql_queries => %w[Query3 Query4 Query5] } }

    before(:each) do
      subject.record env, :sql, nil, data_writer
      subject.finalize
    end

    it "adds the current_run to the profile_captures" do
      expect(subject.profile_captures).to eq [{:sql => data}]
    end

    it "sets last_run to current_run" do
      result = {:sql => data}
      expect(ManageIQPerformance.last_run).to eq result
    end

    it "resets the current_run" do
      expect(subject.current_run).to eq Hash.new
    end

    it "stores subsequent runs as well" do
      subject.record env, :sql, nil, Proc.new { data2 }
      subject.finalize
      expect(subject.profile_captures).to eq [{:sql => data}, {:sql => data2}]
    end
  end
end
