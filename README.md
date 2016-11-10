ManageIQPerformance
===================
Libraries and utilities for testing, profiling, benchmarking, and debugging
performance bottlenecks on the ManageIQ application.  Includes, but not limited
to:

  * Middleware for injecting performance monitoring per request by header
  * Executables for testing endpoint performance
  * Railties for convenience including portions of this into the project
  * Automated performance reporting

The goal of this project is to aid in pro actively determining performance
issues and provide a mechanism for easier debugging when issues arise out in
the field.


Installation
------------

Add this line to your ManageIQ/manageiq Gemfile.dev.rb:

```ruby
gem 'miq_performance', :github => 'NickLaMuro/miq_performance'
```

Since this is meant to be modular, you can include specific parts of the gem
that you need in the ManageIQ application by modifying the `:require` statement
in the above `gem` invocation:

```ruby
gem 'miq_performance', :require => [ 'miq_performance/railtie/rake_tasks',
                                     'miq_performance/railtie/middleware' ],
                       :github => 'NickLaMuro/miq_performance'
```

This will only then load the railties for the `rake_tasks` and the
`middleware`, but nothing else (currently, this is all there is...)

To make use of some of the middleware components and other gem specific
features, you will also need to include their corresponding gems.  For example,
the `stackprof` middleware requires the
[`stackprof`](https://github.com/tmm1/stackprof) gem, so include it by
including the following in your `Gemfile.dev.rb`:

```ruby
gem 'stackprof', :require => false
```


Usage
-----

### Middleware

The middleware included in this gem is a modular middleware, and will add
components based on if the gem required by the component is present.

The three middleware components currently available are:

* `active_support_timers`
* `active_record_queries`
* `stackprof`

Each will write their data to a directory that is configured on application
boot, something like `tmp/miq_performance/run_123456789`, where `123456789` is
a timestamp of when the application was booted.

From there, any request with the header `WITH_PERFORMANCE_MONITORING`, will
then run the component reporters and output the results to that directory.

Results are grouped by path, so requests to `/` will show up in a subdirectory
of `root`, and requests to `/vm_infa/explorer` will be put in
`vm_infra-explorer`:

```
tmp/
├── miq_performance
│   └── run_1472612126
│       ├── root
│       │   ├── request_1472612151930416.info
│       │   ├── request_1472612151930416.queries
│       │   └── request_1472612151930416.stackprof
│       └── vm_infra-explorer
│           ├── request_1472612151930416.info
│           ├── request_1472612151930416.queries
│           └── request_1472612151930416.stackprof
```


#### `ActiveSupportTimers`

This acts similarly to the `Started`/`Completed` timers found in the log, and
is implemented in a similar fashion to [this blog
post](https://signalvnoise.com/posts/3091-pssst-your-rails-application-has-a-secret-to-tell-you)
by Basecamp.  This will write an `.info` file that will include the controller,
action, path, status, and timers (total, views, and db) of the request.


#### `ActiveRecordQueries`

Also making use of `ActiveSupport::Notifications`, these currently log the
following specifics in regards to the queries made by your application on a
request:

* Total number of sql queries made in during the request
* Data about each query fired, which includes the following:
  - SQL generated for the query
  - Time taken for the query to be executed in the DB
  - `params` passed into the query
* Total number of rows returned
* Number of rows returned per class


#### `Stackprof`

This will run the stackprof profiler for the request, and output it to a
`.stackprof` file.

The `Stackprof` middleware component can currently be configured using HTTP
headers on a per request basis:

* `MIQ_PERF_STACKPROF_RAW` will configured the `raw` output, which is require
  if you want to use the stackprof output to generate a flamegraph (defaults to
  `true`)
* `MIQ_PERF_STACKPROF_MODE` will change the profiling mode.  You can choose
  between 'wall', 'cpu', and 'object'.  Default is 'wall'.
* `MIQ_PERF_STACKPROF_INTERVAL` will change how often the stack is profiled.
  Default is `1000` (in microseconds).

More info can be found on the [github page](https://github.com/tmm1/stackprof)


### Raketasks

`miq_performance` comes with 3 rake tasks:

* `rake miq_performance:build_request_file`
* `rake miq_performance:benchmark`
* `rake miq_performance:benchmark_url["<REQUEST_PATH>"]`


#### `build_request_file`

This will build a plaintext `Requestfile` in the following format:

```
GET  => '/'
POST => '/vm/tree_select
GET  => '/vm/show/12345'
```

To do it, it will connect to the database for your rails application to fill in
IDs for requests, and other params necessary to successfully make a request
(currently only fills in IDs, but more options are planned).


#### `benchmark`

This will generate or load a previously generated `Requestfile`, and make
requests in serial against the application, using the
`WITH_PERFORMANCE_MONITORING` and the `MIQ_PERF_TIMESTAMP` headers for each
request.

You can configure the endpoint for the `host` using the `MIQ_HOST` or
`CFME_HOST` environment variables.  Defaults to `http://localhost:3000`.


#### `benchmark_url["<REQUEST_PATH>"]`

Similar to the `benchmark` task, but is used for one off requests.  Can be used
like so:

```
$ rake miq_performance:benchmark_url["/vm/show/123456"]
```

Currently this only supports `GET` requests, but will also accept the
`MIQ_HOST` and `CFME_HOST` variables.



TODO
----
* Some tests.. hey, what a thought!
* Add configuration file of some sort
* Add Profiling around MiqQueue
* Better Requestfile generation
* Handle CSRF Token better in `Requestor`
* Include support for headless browser requests through Phantom.js/Poltergeist
* Add more middleware components (`statsd`, `rake-mini-profiler`, etc.)
* Human readable report generation
* Tooling around data analysis and debugging


## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/NickLaMuro/miq_performance.
