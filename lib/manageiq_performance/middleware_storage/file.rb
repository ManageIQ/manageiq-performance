require "yaml"
require "fileutils"
require "manageiq_performance/configuration"

module ManageIQPerformance
  module MiddlewareStorage
    class File
      attr_reader :miq_performance_suite_dir

      def initialize
        create_suite_dir
      end

      def record env, filetype, _, file_data
        write_report_file filename(env, filetype), &file_data
      end

      # noop:  Files have already been written at this point
      def finalize; end

      private

      def create_suite_dir
        base_dir = ManageIQPerformance.config.default_dir
        suite_dir = ::File.join(base_dir, "run_#{Time.now.to_i}")
        FileUtils.mkdir_p(suite_dir)

        @miq_performance_suite_dir = suite_dir
      end

      def write_report_file report_filename
        filepath = ::File.join(miq_performance_suite_dir, report_filename)
        FileUtils.mkdir_p(::File.dirname filepath)
        ::File.open(filepath, 'wb') do |file_io|
          data = yield
          file_io.write(format_data data)
        end
        report_filename
      end

      def filename env, ext=:data
        request_path = format_path_for_filename env['REQUEST_PATH']
        timestamp    = request_timestamp env

        "#{request_path}/request_#{timestamp}.#{ext}"
      end

      def format_path_for_filename path
        request_path = path.to_s.gsub("/", "%").sub(/^%/, '')
        request_path = "root" if request_path == ""
        request_path
      end

      def request_timestamp env
        env['HTTP_MIQ_PERF_TIMESTAMP'] || (Time.now.to_f * 1000000).to_i
      end

      private

      def format_data data
        case data
        when Hash
          if ManageIQPerformance.config.format_yaml_stack_traces? && data[:queries]
            ast = Psych::Visitors::YAMLTree.create
            ast << data
            ast.tree.grep(Psych::Nodes::Mapping).each do |mapping|
              mapping.children.each_slice(2).each do |k, seq|
                if k.value == ":stacktrace"
                  seq.children.grep(Psych::Nodes::Scalar) do |node|
                    node.plain  = true
                    node.quoted = false
                    node.style  = Psych::Nodes::Scalar::ANY
                  end
                end
              end
            end
            ast.tree.yaml(nil, :line_width => -1) # -1 == unlimited
          else
            data.to_yaml
          end
        else
          data
        end
      end
    end
  end
end
