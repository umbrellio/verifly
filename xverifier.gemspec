# coding: utf-8
# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'xverifier/version'

Gem::Specification.new do |spec|
  spec.name          = 'xverifier'
  spec.version       = XVerifier::VERSION
  spec.authors       = ['Alexander Smirnov']
  spec.email         = ['begdory4@gmail.com']

  spec.summary       = ''
  spec.description   = ''
  spec.homepage      = 'http://example.com'

  spec.files         = Dir['lib/**/*.rb']
  spec.executables   = []
  spec.require_paths = %w(lib)

  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'bundler', '~> 1.14'
  spec.add_development_dependency 'rake', '~> 10.5'
  spec.add_development_dependency 'rspec', '~> 3.5'
  spec.add_development_dependency 'rubocop', '~> 0.48'
  spec.add_development_dependency 'yard', '~> 0.9.8'
  spec.add_development_dependency 'launchy', '~> 2.4'
  spec.add_development_dependency 'coveralls', '~> 0.8.19'
end
