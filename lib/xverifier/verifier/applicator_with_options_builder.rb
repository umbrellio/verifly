# frozen_string_literal: true

module XVerifier
  class Verifier
    # Builds ApplicatorWithOptions from different invocation styles.
    # @api private
    # @attr base [Class]
    #   class for which applicator_with_options should be built
    # @attr args [Array]
    #   array of arguments Verifier.verify invoked with
    # @attr block [Proc]
    #   block Verifier.verify invoked with
    ApplicatorWithOptionsBuilder = Struct.new(:base, :args, :block)
    class ApplicatorWithOptionsBuilder
      # @!method self.call(base)
      # transforms `verify` arguments to class attributes
      # and invokes calculation
      # @raise [ArgumentError]
      # @return [ApplicatorWithOptions] resulting applicator_with_options
      def self.call(base, *args, &block)
        new(base, args, block).call
      end

      # Tries different invocation styles until one matches
      # @see #try_block
      # @see #try_nesting
      # @see #default
      # @raise [ArgumentError]
      # @return [ApplicatorWithOptions] resulting applicator_with_options
      def call
        try_block || try_nesting || default
      end

      private

      # @example with options
      #   verify(if: true) { ... }
      # @example without options
      #   verify { ... }
      # @return [ApplicatorWithOptions]
      def try_block
        ApplicatorWithOptions.new(block, *args) if block
      end

      # @example correct
      #   verify SubVerifier
      # @example incorrect
      #   verify Class
      # @raise [ArgumentError]
      # @return [ApplicatorWithOptions]
      def try_nesting
        verifier, *rest = args
        return unless verifier.is_a?(Class)
        raise ArgumentError, <<~ERROR unless verifier < base
          Nested verifiers should be inherited from verifier they nested are in
        ERROR

        applicable = lambda do |context|
          messages.concat(verifier.call(model, context))
        end

        ApplicatorWithOptions.new(applicable, *rest)
      end

      # Simply passes args to ApplicatorWithOptions
      # @example
      #   verify(:foo, unless: false)
      # @return [ApplicatorWithOptions]
      def default
        ApplicatorWithOptions.new(*args)
      end
    end
  end
end
