require "manageiq_performance/reporter"

describe ManageIQPerformance::Reporter do
  let(:run_dir) { "/foo/bar" }
  subject       { described_class.new run_dir }

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
