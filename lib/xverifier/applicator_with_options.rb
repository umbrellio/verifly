# frozen_string_literal: true

module XVerifier
  # An applicator with useful options
  # @example if
  #   ApplicatorWithOptions.new(action, if: true)
  # @example unless
  #   ApplicatorWithOptions.new(action, unless: false)
  # @attr action [Applicator]
  #   main action to apply on call
  # @attr if_condition [Applicator]
  #   main action only apply if this applies to truthy value
  # @attr unless_condition [Applicator]
  #   main action only apply if this applies to falsey value
  class ApplicatorWithOptions
    attr_accessor :action, :if_condition, :unless_condition

    # @param action [applicable] main action
    # @option options [applicable] :if
    #   main action only apply if this applies to truthy value
    # @option options [applicable] :unless
    #   main action only apply if this applies to falsey value
    def initialize(action, **options)
      self.action = Applicator.build(action)
      self.if_condition = Applicator.build(options.fetch(:if, true))
      self.unless_condition = Applicator.build(options.fetch(:unless, false))
    end

    # Applies main action if if_condition applyd to truthy value
    # and unless_condition applyd to falsey value
    # @param binding_ [#instance_exec]
    #   binding to apply (see Applicator)
    # @param context
    #   generic context to apply (see Applicator)
    # @return main action application result
    # @return [nil] if condition checks failed
    def call(binding_, context)
      return unless if_condition.call(binding_, context)
      return if unless_condition.call(binding_, context)
      action.call(binding_, context)
    end
  end
end
