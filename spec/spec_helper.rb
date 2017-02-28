$LOAD_PATH.unshift File.expand_path "../..", __FILE__

require 'tempfile'

CONFIG_FILE_NAME = Tempfile.new('config').tap { |x| x.close } # sorry, not unlinking
RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended, and will default to
    # `true` in RSpec 4.
    mocks.verify_partial_doubles = true
  end

  # This option will default to `:apply_to_host_groups` in RSpec 4 (and will
  # have no way to turn it off -- the option exists only for backwards
  # compatibility in RSpec 3). It causes shared context metadata to be
  # inherited by the metadata hash of host groups and examples, rather than
  # triggering implicit auto-inclusion in groups with matching metadata.
  config.shared_context_metadata_behavior = :apply_to_host_groups

  # Allows RSpec to persist some state between runs in order to support
  # the `--only-failures` and `--next-failure` CLI options. We recommend
  # you configure your source control system to ignore this file.
  config.example_status_persistence_file_path = "spec/examples.txt"
  config.warnings = true
  config.order = :random

  if config.files_to_run.one?
    config.default_formatter = 'doc'
  end

  Kernel.srand config.seed

  # Always reset the config before each test
  config.before(:each) do
    ManageIQPerformance.instance_variable_set :@config, nil

    if defined? ManageIQPerformance::Configuration
      ManageIQPerformance::Configuration.instance_variable_set :@config_file_location, CONFIG_FILE_NAME
    end
  end
end

# Stub Rails
module Rails
  Application = Struct.new :config
  Config      = Struct.new :filter_parameters

  def self.root
    File.expand_path File.join(".."), File.dirname(__FILE__)
  end

  def self.application
    Application.new Config.new([:password, :verify, :data])
  end
end


# Strip Heardoc

class String
  def __strip_heredoc
    gsub(/^#{scan(/^[ \t]*(?=\S)/).min}/, ''.freeze)
  end
end
