# frozen_string_literal: true

# XVerifier provides several usefull classes, but most important
# is Verifier. Other provided classes are it's dependency.
# See README.md or their own documentation for more info about usage
module XVerifier
  autoload :VERSION, 'xverifier/version'

  autoload :Applicator, 'xverifier/applicator'
  autoload :ApplicatorWithOptions, 'xverifier/applicator_with_options'
  autoload :ClassBuilder, 'xverifier/class_builder'
  autoload :Verifier, 'xverifier/verifier'
end
