require "bundler"
require "manageiq_performance/require_tree"

describe ManageIQPerformance::RequireTree do
  subject      { described_class.new "TOP" }

  # Empty the required_by class var for each test
  before       { described_class.required_by.delete_if {|k,v| true } }

  let(:child1) { described_class.new("child1").tap {|c| c.cost = 10} }
  let(:child2) { described_class.new("child2").tap {|c| c.cost = 20} }
  let(:out) { StringIO.new }

  describe "#initialize" do
    it "sets the name" do
      expect(subject.name).to eq("TOP")
    end

    it "defaults the children to {}" do
      expect(subject.instance_variable_get(:@children)).to eq({})
    end

    it "defaults to having a nil parent" do
      expect(subject.parent).to be_nil
    end
  end

  describe "#children" do
    before do
      subject.instance_variable_set :@children, {
        child1.name.to_s => child1,
        child2.name.to_s => child2
      }
    end

    it "returns the subtrees as an array" do
      expect(subject.children).to eq [child1, child2]
    end
  end

  describe "#<<" do
    context "adding one child" do
      before do
        subject << child1
      end

      it "adds child to the tree" do
        expect(subject.children).to eq [child1]
        expect(subject[child1.name]).to eq child1
      end

      it "sets the parent of the child" do
        expect(child1.parent).to eq subject
      end

      it "includes the child as being required by the parent" do
        expect(described_class.required_by).to eq({"child1" => ["TOP"]})
      end
    end

    context "adding two children" do
      before do
        subject << child1
        subject << child2
      end

      it "adds child to the tree" do
        expect(subject.children).to eq [child1, child2]
        expect(subject[child1.name]).to eq child1
        expect(subject[child2.name]).to eq child2
      end

      it "sets the parent of the child" do
        expect(child1.parent).to eq subject
        expect(child2.parent).to eq subject
      end

      it "includes the child as being required by the parent" do
        expect(described_class.required_by["child1"]).to eq ["TOP"]
        expect(described_class.required_by["child2"]).to eq ["TOP"]
      end
    end
  end

  describe "#cost" do
    it "returns 0 cost is not set" do
      expect(subject.cost).to eq(0)
    end

    it "returns the set value when set" do
      subject.cost = 10
      expect(subject.cost).to eq(10)
    end
  end

  describe "#sorted_children" do
    before do
      subject << child1
      subject << child2
    end

    it "returns children sorted by highest cost" do
      expect(subject.sorted_children).to eq [child2, child1]
    end
  end

  describe "#short_name" do
    it "removes the gem dir path and lib dir from the file location" do
      rspec = RSpec.method(:world).source_location.first
      tree  = described_class.new(rspec)
      expect(tree.short_name).to eq "rspec/core.rb"
    end

    it "removes the bundler dir path and lib dir from the file location" do
      rspec = File.join Bundler.install_path, "rspec-111ffff", "lib", "rspec", "core.rb"
      tree  = described_class.new(rspec)
      expect(tree.short_name).to eq "rspec/core.rb"
    end

    it "removes the Rails.root/CWD from the file location" do
      require_tree = ManageIQPerformance::RequireTree.method(:required_by)
                                                     .source_location.first
      tree = described_class.new(require_tree)
      expect(tree.short_name).to eq "lib/manageiq_performance/require_tree.rb"
    end
  end

  describe "#to_string" do
    it "prints the short_name and cost (rounded to 4 digits)" do
      subject.cost = 0.12345
      expect(subject.to_string).to eq("TOP: 0.1235 MiB")
    end

    it "prints any other parents that also required it" do
      subject << child1
      child2  << child1
      child1.cost = 0.234567

      expect(child1.to_string).to eq("child1: 0.2346 MiB (Also required by: TOP)")
    end

    it "only prints up to 2 parents" do
      child3 = described_class.new("child3")
      child4 = described_class.new("child4")
      child5 = described_class.new("child5")

      subject << child1
      child2  << child1
      child3  << child1
      child4  << child1
      child5  << child1
      child1.cost = 0.234567

      expected = "child1: 0.2346 MiB (Also required by: TOP, child2, and 2 others)"
      expect(child1.to_string).to eq(expected)
    end
  end

  describe "#print_sorted_children" do
    before do
      subject.cost = 30
      subject << child2
      child2  << child1
    end

    it "prints the tree" do
      expected = <<-EXPECTED.gsub(/^ {8}/, '')
        TOP: 30.0 MiB
          child2: 20.0 MiB
            child1: 10.0 MiB
      EXPECTED
      subject.print_sorted_children(0, out)
      out.rewind
      expect(out.read).to eq expected
    end

    it "removes leafs that don't meet the CUT_OFF" do
      ENV["CUT_OFF"] = "15"

      expected = <<-EXPECTED.gsub(/^ {8}/, '')
        TOP: 30.0 MiB
          child2: 20.0 MiB
      EXPECTED

      subject.print_sorted_children(0, out)
      out.rewind
      expect(out.read).to eq expected

      ENV["CUT_OFF"] = nil
    end
  end

  describe "#print_summary" do
    before do
      subject.cost = 30
      subject << child1
      child1  << child2
    end

    it "prints a summary of the top level requires" do
      long_name      = "app/models/manageiq/providers/network_manager.rb"
      big_name_child = described_class.new(long_name)
      subject       << big_name_child

      expected = <<-EXPECTED.gsub(/^ {8}/, '')
        SUMMARY ( TOTAL COST: 30.0 MiB )
        --------------------------------------------------------------
        child1                                           | 10.0000 MiB
        app/models/manageiq/providers/network_manager.rb |  0.0000 MiB
      EXPECTED

      subject.print_summary(out)
      out.rewind
      expect(out.read).to eq expected
    end

    it "has a minimum table length" do
      expected = <<-EXPECTED.gsub(/^ {8}/, '')
        SUMMARY ( TOTAL COST: 30.0 MiB )
        -------------------------------------------------------------
        child1                                          | 10.0000 MiB
      EXPECTED

      subject.print_summary(out)
      out.rewind
      expect(out.read).to eq expected
    end

    it "removes results below the CUT_OFF" do
      ENV["CUT_OFF"] = "15"

      expected = <<-EXPECTED.gsub(/^ {8}/, '')
        SUMMARY ( TOTAL COST: 30.0 MiB )
        -------------------------------------------------------------
      EXPECTED

      subject.print_summary(out)
      out.rewind
      expect(out.read).to eq expected

      ENV["CUT_OFF"] = nil
    end
  end
end
