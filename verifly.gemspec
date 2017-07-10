# coding: utf-8
# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "verifly/version"

Gem::Specification.new do |spec| # rubocop:disable Metrics/BlockLength
  spec.name = "verifly"
  spec.version = Verifly::VERSION
  spec.authors = ["Alexander Smirnov"]
  spec.email = ["begdory4@gmail.com"]

  spec.summary = <<~SUMMARY.gsub(/\s+/, " ")
    See more info at
    https://www.rubydoc.info/gems/verifly/#{Verifly::VERSION}
  SUMMARY

  spec.description = <<~DESCRIPTION.gsub(/\s+/, " ")
    An api to run sequential checks like 'ActiveModel::Validations'
    do, but with generic messages instead of errors.
    #{spec.summary}
  DESCRIPTION

  spec.homepage = "https://github.com/umbrellio/verifly"
  spec.license = "MIT"

  spec.files = Dir["lib/**/*.rb"]
  spec.files << "README.md"
  # You can also add the following to your .gemspec to have YARD
  # document your gem on install
  spec.metadata["yard.run"] = "yri"

  spec.executables = []
  spec.require_paths = %w[lib]

  spec.required_ruby_version = "~> 2.3"

  spec.add_development_dependency "pry", "~> 0.10"
  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 10.5"
  spec.add_development_dependency "rspec", "~> 3.5"
  spec.add_development_dependency "yard", "~> 0.9.8"
  spec.add_development_dependency "launchy", "~> 2.4"
  spec.add_development_dependency "coveralls", "~> 0.8.19"
  spec.add_development_dependency "rspec-its", "~> 1.1"

  spec.add_development_dependency "activesupport" # Fot integration tests

  spec.add_development_dependency "rubocop-config-umbrellio", "~> 0.49"
end
