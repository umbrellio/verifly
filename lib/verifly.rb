# frozen_string_literal: true

# Verifly provides several useful classes, but Verifier is the most
# important one, while others depend on it.
# See README.md or in-code documentation for more info.
module Verifly
  autoload :VERSION, "verifly/version"

  autoload :Applicator, "verifly/applicator"
  autoload :ApplicatorWithOptions, "verifly/applicator_with_options"
  autoload :ClassBuilder, "verifly/class_builder"
  autoload :DependentCallbacks, "verifly/dependent_callbacks"
  autoload :Verifier, "verifly/verifier"
end
