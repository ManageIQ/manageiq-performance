# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'manageiq_performance/version'

Gem::Specification.new do |spec|
  spec.name          = "manageiq-performance"
  spec.version       = ManageIQPerformance::VERSION
  spec.authors       = ["Nick LaMuro"]
  spec.email         = ["nicklamuro@gmail.com"]

  spec.homepage      = "http://github.com/ManageIQ/manageiq-performance"
  spec.summary       = "Perfomance Utils and Benchmarking for the ManageIQ application"

  spec.description   = <<-DESC.gsub(/^ {4}/, '')
    Libraries and utilities for testing, profiling, benchmarking, and debugging
    performance bottlenecks on the ManageIQ application.  Includes, but not
    limited to:

      * Middleware for injecting performance monitoring per request by header
      * Executables for testing endpoint performance
      * Railties for convenience including portions of this into the project
      * Automated performance reporting

    The goal of this project is to aid in pro actively determining performance
    issues and provide a mechanism for easier debugging when issues arise out
    in the field.
  DESC

  spec.files         = Dir["lib/**/*", "bin/*"]
  spec.bindir        = "bin"
  spec.executables   = Dir["bin/*"].map { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", ">= 1.3.0", "< 2.0"
  spec.add_development_dependency "rake",    "~> 10.0"
  spec.add_development_dependency "rspec",   "~> 3.5.0"

  spec.add_development_dependency "stackprof"
  spec.add_development_dependency "rails"
end
