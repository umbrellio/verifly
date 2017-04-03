# frozen_string_literal: true

# Verifly provides several usefull classes, but most important
# is Verifier. Other provided classes are it's dependency.
# See README.md or their own documentation for more info about usage
module Verifly
  autoload :VERSION, 'verifly/version'

  autoload :Applicator, 'verifly/applicator'
  autoload :ApplicatorWithOptions, 'verifly/applicator_with_options'
  autoload :ClassBuilder, 'verifly/class_builder'
  autoload :Verifier, 'verifly/verifier'
end
