# frozen_string_literal: true

# @todo write a good readme
module XVerifier
  autoload :VERSION, 'xverifier/version'

  autoload :Applicator, 'xverifier/applicator'
  autoload :ApplicatorWithOptions, 'xverifier/applicator_with_options'
  autoload :ClassBuilder, 'xverifier/class_builder'
  autoload :Verifier, 'xverifier/verifier'
end
