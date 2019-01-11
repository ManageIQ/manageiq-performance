# This code is almost a complete knockoff of the
# derailed_benchmarks/core_ext/kernel_require code, with a few modifications to
# how the code performs and is written.
#
# derailed_benchmarks:  https://github.com/schneems/derailed_benchmarks
# Copyright (c) 2017 Richard Schneeman
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require_relative "../utils/process_memory"
require_relative "../require_tree"

module Kernel
  alias original_require require

  def require(file)
    Kernel.require(file)
  end

  def require_relative(file)
    require File.expand_path("../#{file}", caller_locations(1, 1)[0].absolute_path)
  end

  class << self
    attr_writer :require_stack
    alias original_require require
    alias :original_require_relative :require_relative

    def require_stack
      @require_stack ||= []
    end
  end

  def self.measure_memory_impact(file, &block)
    node   = ::ManageIQPerformance::RequireTree.new(file)

    parent = require_stack.last
    parent << node
    require_stack.push(node)
    begin
      before = ::ManageIQPerformance::Utils::ProcessMemory.get
      block.call file
    ensure
      require_stack.pop # node
      after = ::ManageIQPerformance::Utils::ProcessMemory.get
    end
    node.cost = after - before
  end
end

# Top level node that will store all require information for the entire app
TOP_REQUIRE = ManageIQPerformance::RequireTree.new("TOP")
::Kernel.require_stack.push(TOP_REQUIRE)

Kernel.define_singleton_method(:require) do |file|
  # puts "before all:  #{file}"
  measure_memory_impact(file) { |f| original_require(f) }
end

# Don't forget to assign a cost to the top level
cost_before_requiring_anything = ::ManageIQPerformance::Utils::ProcessMemory.get
TOP_REQUIRE.cost = cost_before_requiring_anything
def TOP_REQUIRE.set_top_require_cost
  self.cost = ::ManageIQPerformance::Utils::ProcessMemory.get - cost
end
