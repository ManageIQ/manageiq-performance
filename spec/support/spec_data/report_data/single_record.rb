module SpecData
  module ReportData
    SINGLE_RECORD = {
      "foo" => {
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
      }
    }

    SINGLE_RECORD_MULTIPLE_REQUESTS = {
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

    SINGLE_RECORD_NO_QUERY_DATA = {
      "foo" => {
        "avgs" => {
          "ms"           => 500,
          "activerecord" => 74,
          "queries"      => 0,
          "rows"         => 0,
          "elapsed_time" => 0
        },
        "ms"           => [500],
        "activerecord" => [74]
      }
    }

    SINGLE_RECORD_NO_INFO_DATA = {
      "foo" => {
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
      }
    }
  end
end
