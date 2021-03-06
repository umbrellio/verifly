# frozen_string_literal: true

module Verifly
  # An applicator with useful options
  # @example if
  #   ApplicatorWithOptions.new(action, if: true)
  # @example unless
  #   ApplicatorWithOptions.new(action, unless: false)
  # @attr action [Applicator]
  #   main action to apply on call
  # @attr if_condition [Applicator]
  #   main action only apply if condition evaluates to truthy value
  # @attr unless_condition [Applicator]
  #   main action only apply if condition evaluates to falsey value
  class ApplicatorWithOptions
    attr_accessor :action, :if_condition, :unless_condition

    # @!method initialize(action = block, options = {}, &block)
    # @param action [applicable] main action
    # @option options [applicable] :if
    #   main action is only applied if this evaluates to truthy value
    # @option options [applicable] :unless
    #   main action is only applied if this evaluates to falsey value
    # @raise [ArgumentError] if there is more than two arguments and block
    # @raise [ArgumentError] if there is zero arguments and no block
    def initialize(*args, &block)
      action, options = normalize_options(*args, &block)

      self.action = Applicator.build(action)
      self.if_condition = Applicator.build(options.fetch(:if, true))
      self.unless_condition = Applicator.build(options.fetch(:unless, false))
    end

    # Applies main action if if_condition is evaluated to truthy value
    # and unless_condition is evaluated to falsey value
    # @param binding_ [#instance_exec]
    #   binding to apply (see Applicator)
    # @param context
    #   generic context to apply (see Applicator)
    # @return main action application result
    # @return [nil] if condition checks failed
    def call(binding_, *context)
      return unless if_condition.call(binding_, *context)
      return if unless_condition.call(binding_, *context)
      action.call(binding_, *context)
    end

    private

    def normalize_options(*args, &block)
      action, options, *rest = block ? [block, *args] : args
      options ||= {}
      raise ArgumentError unless action && rest.empty?

      [action, options]
    end
  end
end
