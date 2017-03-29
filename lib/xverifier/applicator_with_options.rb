# frozen_string_literal: true

module XVerifier
  class ApplicatorWithOptions
    attr_accessor :action, :if_condition, :unless_condition

    def initialize(action, **options)
      self.action = Applicator.build(action)
      self.if_condition = Applicator.build(options.fetch(:if, true))
      self.unless_condition = Applicator.build(options.fetch(:unless, false))
    end

    def call(binding, context)
      return unless if_condition.call(binding, context)
      return if unless_condition.call(binding, context)
      action.call(binding, context)
    end
  end
end
