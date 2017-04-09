# coding: utf-8
# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'verifly/version'

Gem::Specification.new do |spec|
  spec.name = 'verifly'
  spec.version = Verifly::VERSION
  spec.authors = ['Alexander Smirnov']
  spec.email = ['begdory4@gmail.com']

  spec.summary = <<~SUMMARY.gsub(/\s+/, ' ')
    An api to run sequential checks like 'ActiveModel::Validations'
    do, but with generic messages instead of errors
  SUMMARY

  spec.description = <<~DESCRIPTION.gsub(/\s+/, ' ')
    See more info at
    http://www.rubydoc.info/gems/verifly/#{Verifly::VERSION}
  DESCRIPTION
  spec.homepage = 'https://github.com/umbrellio/verifly'
  spec.license = 'MIT'

  spec.files = Dir['lib/**/*.rb']
  spec.executables = []
  spec.require_paths = %w[lib]

  spec.required_ruby_version = '~> 2.3'
  spec.add_development_dependency 'pry', '~> 0.10'
  spec.add_development_dependency 'bundler', '~> 1.14'
  spec.add_development_dependency 'rake', '~> 10.5'
  spec.add_development_dependency 'rspec', '~> 3.5'
  spec.add_development_dependency 'rubocop', '~> 0.48'
  spec.add_development_dependency 'yard', '~> 0.9.8'
  spec.add_development_dependency 'launchy', '~> 2.4'
  spec.add_development_dependency 'coveralls', '~> 0.8.19'
  spec.add_development_dependency 'rubocop-rspec', '~> 1.15'
  spec.add_development_dependency 'rspec-its', '~> 1.1'
end
