# frozen_string_literal: true

module Verifly
  module DependentCallbacks
    # ApplicatorWithOptions improved to handle everything needed in DependentCallbacks
    # @attr name [Symbol?] callback name
    # @attr position [:before, :after, :around] callback position
    # @attr before [[Symbol]] names of calblacks before which this is
    # @attr after [[Symbol]] names of calblacks after which this is
    class Callback < ApplicatorWithOptions
      # Available positions of calblack: before, after or around action
      POSITIONS = %i[before after around].freeze

      attr_accessor :name, :position, :before, :after

      # @!method initialize(position, action = block, options = {}, &block)
      # @see ApplicatorWithOptions#initialize
      # @param position [:before, :after, :around] position
      # @param action [applicable] main action
      # @option options [applicable] :if
      #   main action is only applied if this evaluates to truthy value
      # @option options [applicable] :unless
      #   main action is only applied if this evaluates to falsey value
      # @option options [Symbol] :name
      #   name override for callback. By default, name is taken from applicable if it is a symbol
      #   or set to nil. This option allows to use named applicables like proc
      # @option options [[Symbol]] :insert_before
      #   array of callback names which should be sequenced after current.
      #   Note, that if position == :after, sequence would go backwards
      # @option options [[Symbol]] :require
      #   array of callback names which should be sequenced before current.
      # @raise [ArgumentError] if there is more than three arguments and block
      # @raise [ArgumentError] if there is one argument and no block
      def initialize(position, *args, &block)
        super(*args, &block)

        action, options = normalize_options(*args, &block)

        self.name = options.fetch(:name) { action if action.is_a?(Symbol) }

        self.position = position
        raise "#{position} should be one of #{POSITIONS}" unless POSITIONS.include?(position)

        self.before = Array(options.fetch(:insert_before, []))
        self.after = Array(options.fetch(:require, []))
      end

      # call applicable around block depending on it's position
      # @param binding_ [#instance_exec]
      # @param context
      # @yield after before or inside applicable
      def call_around(binding_, *context, &block)
        DependentCallbacks.logger.debug "Running #{name || action.source} with #{context}"

        case position
        when :before
          call(binding_, *context)
          yield
        when :after
          yield
          call(binding_, *context)
        when :around
          call(binding_, block, *context)
        end
      end

      def to_dot_label(binding_)
        template_path = File.expand_path("callback.dothtml.erb", __dir__)
        erb = ERB.new(File.read(template_path))
        erb.filename = template_path
        erb.result(binding)
      end
    end
  end
end
