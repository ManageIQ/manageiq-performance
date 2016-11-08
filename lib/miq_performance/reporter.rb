module MiqPerformance
  class Reporter
    HEADERS = {
      "ms" => %w[ms],
      "queries" => %w[queries],
      "query (ms)" => %w[activerecord elapsed_time],
      "rows" => %w[rows]
    }

    def self.build(run_dir)
      new(run_dir).build
    end

    def initialize(run_dir)
      @run_dir = run_dir
      @report_data = {}
    end

    def build
      collect_data
      print_data
    end

    private

    # Collection

    def collect_data
      Dir["#{@run_dir}/*"].each do |request_dir|
        request_id = File.basename request_dir
        @report_data[request_id]         ||= {}
        @report_data[request_id]["avgs"] ||= {}

        gather_request_times request_dir, request_id
        gather_db_info       request_dir, request_id
      end
    end

    def gather_request_times request_dir, request_id
      Dir["#{request_dir}/*.info"].inject(@report_data[request_id]) do |data, info_file|
        info = YAML.load_file(info_file)

        data["ms"]           ||= []
        data["activerecord"] ||= []
        data["ms"]           << info.fetch('time', {})['total'].to_i
        data["activerecord"] << info.fetch('time', {})['activerecord'].to_i
        data
      end

      @report_data[request_id]["avgs"]["ms"]           = @report_data[request_id]["ms"].inject(0, :+)
      @report_data[request_id]["avgs"]["activerecord"] = @report_data[request_id]["activerecord"].inject(0, :+)
    end

    def gather_db_info request_dir, request_id
      Dir["#{request_dir}/*.queries"].inject(@report_data[request_id]) do |data, info_file|
        queries = YAML.load_file(info_file)

        data["queries"]      ||= []
        data["rows"]         ||= []
        data["elapsed_time"] ||= []
        data["queries"]      << queries[:total_queries]
        data["rows"]         << queries[:total_rows]
        data["elapsed_time"] << queries.fetch(:queries, []).map {|q| q[:elapsed_time] }.inject(0.0, :+)
        data
      end

      @report_data[request_id]["avgs"]["queries"]      = @report_data[request_id]["queries"].inject(0, :+)
      @report_data[request_id]["avgs"]["rows"]         = @report_data[request_id]["rows"].inject(0, :+)
      @report_data[request_id]["avgs"]["elapsed_time"] = @report_data[request_id]["elapsed_time"].inject(0, :+)
    end

    # Printing

    # Prints the report data
    def print_data
      @report_data.keys.each do |request_id|
        @column_size_for = {}

        puts request_id
        print_headers   request_id
        print_spacers   request_id
        print_row_data  request_id
      end
    end

    # Prints a single row, and defers to the caller to determine what is
    # printed (including determining proper spacing) for each column in the
    # row, passing it the current header for that row.
    #
    # Row columns are split using `|`, and a single space (at a minimum) will
    # always separate the content and the delimiters.
    def print_row
      row =  "| "
      row += HEADERS.keys.map {|hdr| yield hdr }.join(" | ")
      row +=  " |"
      puts row
    end

    # Prints the headers.  Just uses the `hdr` from the yield of `print_rows`
    def print_headers request_id
      print_row do |hdr|
        hdr.rjust(column_size_for hdr, request_id)
      end
    end

    # Prints spacers for each column
    def print_spacers request_id
      print_row do |hdr|
        "---:".rjust(column_size_for hdr, request_id)
      end
    end

    # Prints the data for each row, with each row data value rjust'd to the
    # size for the column, and formatted to 1 decimal point precision (if it is
    # a float)
    def print_row_data request_id
      # Find a header for a count do use in the next line
      count_header = HEADERS.values.flatten.detect do |hdr|
        @report_data[request_id][hdr] and hdr
      end

      @report_data[request_id][count_header].count.times do |i|
        print_row do |hdr|
          value = HEADERS[hdr].map { |header_column|
            @report_data[request_id].fetch(header_column, [])[i].to_i
          }.max
          value = "%.1f" % value unless value.class.ancestors.include?(Integer)
          value.to_s.rjust(column_size_for hdr, request_id)
        end
      end
    end

    # Determines the largest string length character from the following:
    #
    #   - The report data for that column
    #   - The average for that report data
    #   - The column header's length
    #   - The spacer string (`---:`)
    #
    def column_size_for header, request_id
      @column_size_for[header] ||=
        (HEADERS[header].map { |header_column|
          @report_data[request_id][header_column].map {|i|
            value = i.to_s
            value = "%.1f" % value unless value.class.ancestors.include?(Integer)
            value.size
          }.max
        } + [
          header.to_s.length,
          @report_data[request_id]["avgs"][header].to_s.size,
          4 # spacer size
        ]).max
    end
  end
end
