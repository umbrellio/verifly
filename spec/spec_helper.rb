# frozen_string_literal: true

require "bundler/setup"
require "pry"

require "rspec/its"

require "coveralls"
Coveralls.wear!
require "verifly"

RSpec.configure do |config|
  config.default_formatter = "doc" if config.files_to_run.one?

  config.mock_with :rspec do |mocks|
    mocks.verify_doubled_constant_names = true
  end
end

def applicator(applicable)
  Verifly::Applicator.build(applicable)
end
