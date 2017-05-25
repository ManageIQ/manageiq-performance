# This code is almost a complete knockoff of the
# derailed_benchmarks/require_tree code, with some additional additions to
# support different printing types, and a few modifications to how the code
# performs and is written.
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

module ManageIQPerformance
  class RequireTree
    attr_reader   :name
    attr_accessor :cost
    attr_accessor :parent

    RUBYGEMS_DIRS        = Gem.path.map {|path| File.join(path, "gems", "") }
    BUNDLER_DIR          = defined?(Bundler) ? File.join(Bundler.install_path, "") : nil
    ALL_GEM_PATH_ESCAPED = [RUBYGEMS_DIRS, BUNDLER_DIR].flatten.compact
                                                       .map {|p| Regexp.escape p}
    GEM_DIRS_REGEXP      = /(#{ALL_GEM_PATH_ESCAPED.join("|")})([^\/]+\/){2}/.freeze
    PROJECT_DIR_REGEXP   = /^#{defined?(Rails) ? Rails.root : Dir.pwd}\//.freeze

    def self.required_by
      @required_by ||= {}
    end

    def initialize(name)
      @name     = name
      @children = {}
      @cost     = 0
    end

    # Returns array of child nodes
    def children
      @children.values
    end

    def <<(tree)
      @children[tree.name.to_s] = tree
      tree.parent = self
      (self.class.required_by[tree.name.to_s] ||= []) << name
    end

    def [](name)
      @children[name.to_s]
    end

    # Returns sorted array of child nodes from Largest to Smallest
    def sorted_children
      children.sort { |c1, c2| c2.cost <=> c1.cost }
    end

    def short_name
      @short_name ||= name.gsub(GEM_DIRS_REGEXP, '')
                          .gsub(PROJECT_DIR_REGEXP, '')
    end

    def to_string
      str = "#{short_name}: #{cost.round(4)} MiB"
      if parent && self.class.required_by[name.to_s]
        names = self.class.required_by[name.to_s].uniq - [parent.name.to_s]
        if names.any?
          str << " (Also required by: #{names.first(2).join(", ")}"
          str << ", and #{names.count - 2} others" if names.count > 3
          str << ")"
        end
      end
      str
    end

    # Recursively prints all child nodes
    def print_sorted_children(level = 0, out = STDOUT)
      return if cost < ENV['CUT_OFF'].to_f
      out.puts "  " * level + to_string
      level += 1
      sorted_children.each do |child|
        child.print_sorted_children(level, out)
      end
    end

    def print_summary(out = STDOUT)
      longest_name = sorted_children.map { |c| c.short_name.length }.unshift(47).max
      longest_cost = sorted_children.map { |c| ("%.4f" % c.cost).to_s.length }.max

      out.puts "SUMMARY ( TOTAL COST: #{cost.round(4)} MiB )"
      out.puts "-" * (longest_name + longest_cost + 7)

      sorted_children.each do |child|
        next if child.cost < ENV['CUT_OFF'].to_f
        out.puts [
          child.short_name.ljust(longest_name),
          "#{"%.4f" % child.cost} MiB".rjust(longest_cost + 4)
        ].join(' | ')
      end
    end
  end
end
