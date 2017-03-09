module SpecData
  module ReportData
    MULTIPLE_RECORDS = {
      "bar%baz" => {
        "avgs" => {
          "ms"           => 0,
          "activerecord" => 0,
          "queries"      => 20,
          "rows"         => 9375385,
          "elapsed_time" => 73.2
        },
        "queries"      => [20],
        "rows"         => [9375385],
        "elapsed_time" => [73.2]
      },
      "baz%qux" => {
        "avgs" => {
          "ms"           => 500,
          "activerecord" => 74,
          "queries"      => 20,
          "rows"         => 9375385,
          "elapsed_time" => 73.2
        },
        "ms"           => [500],
        "activerecord" => [74],
        "queries"      => [20],
        "rows"         => [9375385],
        "elapsed_time" => [73.2]
      },
      "foo%bar%baz" => {
        "avgs" => {
          "ms"           => 500000,
          "activerecord" => 72,
          "queries"      => 2000000000,
          "rows"         => 245,
          "elapsed_time" => 73.2
        },
        "ms"           => [500000],
        "activerecord" => [72],
        "queries"      => [2000000000],
        "rows"         => [245],
        "elapsed_time" => [73.2]
      },
      "foo" => {
        "avgs" => {
          "ms"           => 168500,
          "activerecord" => 2433336024,
          "queries"      => 666666700,
          "rows"         => 3128285,
          "elapsed_time" => 2433333455.4
        },
        "ms"           => [500, 500000, 5000],
        "activerecord" => [72, 7300000000, 8000],
        "queries"      => [20, 2000000000, 80],
        "rows"         => [95, 9375385, 9375],
        "elapsed_time" => [73.2, 7300000000.2, 292.8]
      }
    }

    MULTIPLE_RECORDS_NO_QUERY_DATA = {
      "foo" => {
        "ms"           => [500],
        "activerecord" => [73.2],
        "avgs" => {
          "ms"           => 500,
          "activerecord" => 73.2
        }
      }
    }

    MULTIPLE_RECORDS_NO_INFO_DATA = {
      "foo" => {
        "queries" => [20],
        "rows"    => [9375385],
        "avgs" => {
          "queries" => 20,
          "rows"    => 9375385
        }
      }
    }
  end
end

