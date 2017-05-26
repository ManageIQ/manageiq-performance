# Takes the main portions of get_process_mem, by Richard Schneeman, to get the
# memory in MiB for the current process at a given point in time.  Uses the
# best method available given the operating system, and hard defines only that
# method (to keep the size of this in memory down).
#
# get_process_mem:  https://github.com/schneems/get_process_mem
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

require "bigdecimal"

module ManageIQPerformance
  module Utils
    module ProcessMemory
      MB_BYTES = ::BigDecimal.new(1_048_576)

    # Travis doesn't seem to like Sys::ProcTable very much, and doesn't seem to
    # return accurate results... so favor reading from /proc/PID/status when
    # available
    if %w[linux].include?(Gem::Platform.local.os) && ENV["CI"] && ENV["TRAVIS"]
      CONVERSION       = {"kb" => 1024, "mb" => 1_048_576, "gb" => 1_073_741_824}.freeze
      PROC_STATUS_FILE = Pathname.new("/proc/#{Process.pid}/status").freeze
      VMRSS_GREP_EXP   = /^VmRSS/

      def self.get
        begin
          rss_line = PROC_STATUS_FILE.each_line.grep(VMRSS_GREP_EXP).first
          return unless rss_line
          return unless (_name, value, unit = rss_line.split(nil)).length == 3
          (CONVERSION[unit.downcase!] * ::BigDecimal.new(value)) / MB_BYTES
        rescue Errno::EACCES, Errno::ENOENT
          0
        end
      end

    # When available, use this.  This doesn't add a large memory footprint, and
    # doesn't cause a bunch of process forking like the one grepping `ps`.
    elsif defined?(Sys::ProcTable) && %w[linux darwin].include?(Gem::Platform.local.os)

      def self.get
        (Sys::ProcTable.ps(Process.pid).rss / MB_BYTES).to_f
      end

    # Not ideal... best to use if nothing else if available, but will cause a
    # decent amount of extra child processes, and significantly increasing
    # the time of your script depending on how many times this is called.
    elsif %w[linux darwin].include?(Gem::Platform.local.os)

      def self.get
        ((1024 * BigDecimal.new(`ps -o rss= -p #{Process.pid}`))/MB_BYTES).to_f
      end

    end

    end
  end
end
