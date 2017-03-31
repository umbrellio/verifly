# frozen_string_literal: true

module XVerifier
  # An applicator with usefull options
  # @example if
  #   ApplicatorWithOptions.new(action, if: true)
  # @example unless
  #   ApplicatorWithOptions.new(action, unless: false)
  # @attr action [Applicator]
  #   main action to applicate on call
  # @attr if_condition [Applicator]
  #   main action only applicate if this applicates to truthy value
  # @attr unless_condition [Applicator]
  #   main action only applicate if this applicates to falsey value
  class ApplicatorWithOptions
    attr_accessor :action, :if_condition, :unless_condition

    # @param action [applicable] main action
    # @option options [applicable] :if
    #   main action only applicate if this applicates to truthy value
    # @option options [applicable] :unless
    #   main action only applicate if this applicates to falsey value
    def initialize(action, **options)
      self.action = Applicator.build(action)
      self.if_condition = Applicator.build(options.fetch(:if, true))
      self.unless_condition = Applicator.build(options.fetch(:unless, false))
    end

    # Applicates main action if if_condition applicated to truthy value
    # and unless_condition applicated to falsey value
    # @param binding_ [#instance_exec]
    #   binding to applicate (see Applicator)
    # @param context
    #   generic context to applicate (see Applicator)
    # @return main action application result
    # @return [nil] if conditions check failed
    def call(binding_, context)
      return unless if_condition.call(binding_, context)
      return if unless_condition.call(binding_, context)
      action.call(binding_, context)
    end
  end
end
