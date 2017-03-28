# frozen_string_literal: true

require 'bundler/setup'
require 'pry'

require 'coveralls'
Coveralls.wear!
require 'xverifier'

RSpec.configure do |config|
  config.default_formatter = 'doc' if config.files_to_run.one?
end
