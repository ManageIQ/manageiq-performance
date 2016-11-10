begin

  require 'capybara/poltergeist'

  # TODO:  Implement this class, but this is left here as a stub as a POC for
  # when we want to do headless browser benchmarking.
  module ManageIQPerformance
    module Requestor
      class Poltergiest
      end
    end
  end

rescue LoadError
  # The `capybara/poltergeist` gem is not installed, so not defining this class
end
