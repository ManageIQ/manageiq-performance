require 'pathname'
require 'stringio'

RSpec::Matchers.define :be_a_valid_child_of do |parent|
  def get_node_for(file)
    if file.is_a?(ManageIQPerformance::RequireTree)
      file
    else
      ::TOP_REQUIRE[file.to_s]
    end
  end

  match do |child_path|
    parent_node = get_node_for(parent)
    child_node = parent_node[child_path]
    !child_node.nil? && child_node.cost <= parent_node.cost
  end

  failure_message do |child_path|
    parent = get_node_for(expected)

    if (child_node = parent[child_path]).nil?
      msg = "be a child of"
    else
      msg = "cost less than"
    end

    <<-MSG.gsub(/^ {6}/, '')
      expected that:

        #{child_node ? "#{child_node.name} #{child_node.cost}MiB" : child_path}

      would #{msg}:

        #{parent.name} #{parent.cost.to_s + "MiB" if child_node}

    MSG
  end
end

describe Kernel do
  let(:fixtures_dir) { Pathname.new File.expand_path("../../support/fixtures", __dir__) }
  let(:parent_file)  { fixtures_dir.join "require", "parent_one.rb" }
  let(:child1_file)  { fixtures_dir.join "require", "child_one.rb" }
  let(:child2_file)  { fixtures_dir.join "require", "child_two.rb" }
  let(:rel_file)     { fixtures_dir.join "require", "relative_child" }
  let(:raise_file)   { fixtures_dir.join "require", "raise_child.rb" }

  before(:all) do
    GC.disable
    silence_warning { require  "manageiq_performance/core_ext/kernel_require" }
  end

  it "builds a require tree for a required file and it's child requires" do
    require parent_file
    ::TOP_REQUIRE.set_top_require_cost
    child2 = ::TOP_REQUIRE[parent_file][child2_file]

    expect(parent_file).to be_a_valid_child_of(::TOP_REQUIRE)
    expect(child1_file).to be_a_valid_child_of(parent_file)
    expect(child2_file).to be_a_valid_child_of(parent_file)
    expect(rel_file).to    be_a_valid_child_of(parent_file)
    expect(raise_file).to  be_a_valid_child_of(child2)
  end

  after(:all) do
    GC.enable

    # Incase we are seeded in a way where this test comes before other tests in
    # the suite, put everything back to the way it was.  Makes things in the
    # suite probably a bit unstable, but you most likely won't be using the
    # core_ext/kernel_require.rb with many of these libs beyond static
    # analysis.
    silence_warning do
      ::Kernel.define_singleton_method(:require) do |file|
        original_require(file)
      end

      module Kernel
        alias require original_require
        class << self
          alias require original_require
          alias :require_relative :original_require_relative
        end
      end
    end
  end

  # We know we are re-defining kernel.require_relative here... that is the
  # point, so ignore the output that rspec sets by default for this case.
  def silence_warning
    old_verbose, $VERBOSE = $VERBOSE, nil
    yield
  ensure
    $VERBOSE = old_verbose
  end
end
