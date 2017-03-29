# frozen_string_literal: true

module XVerifier
  # Verifier is a proto-validator class, which allows to
  # use generic messages formats (instead of errors, which are raw text)
  # @abstract
  #   implement `#message!` method in terms of super
  # @attr model
  #   Generic object to be verified
  # @attr messages [Array]
  #   Array to collect all messages yielded by verifier
  class Verifier
    attr_accessor :model, :messages

    # @example with block
    #   verify { |context| message!() if context[:foo] }
    # @example with proc
    #   verify -> (context) { message!() if context[:foo] }
    # @example cotnext could be ommited from lambda params
    #   verify -> { message!() }, if: -> (context) { context[:foo] }
    # @example with symbol
    #   verify :foo, if: :bar
    #   # calls #foo if #bar is true
    #   # bar could either accept context or not
    # @example with string
    #  verify 'message!() if context[:foo]'
    #  verify 'message!()', if: 'context[:foo]'
    # @example with descedant
    #   verify DescendantClass
    #   # calls DescendantClass.call(model, context) and merges it's messages
    # @param verifier [#to_proc|Symbol|String|Class|nil]
    #   verifier defenition, see examples
    # @option options [#to_proc|Symbol|String|nil] if (true)
    #   call verifier if only block invocation result is truthy
    # @option options [#to_proc|Symbol|String|nil] unless (false)
    #   call verifier if only block invocation result is falsey
    # @yield context on `#verfify!` calls
    # @return [Array] list of all verifiers already defined
    def self.verify(verifier = nil, **options, &block)
      bound_applicators << ApplicatorWithOptions.new(
        *normalize_verify_options(verifier, options, block)
      )
    end

    def self.normalize_verify_options(verifier, options, block)
      if block
        [block, verifier&.to_hash || {}]
      elsif verifier.is_a?(Class) && verifier < self
        [
          ->(context) { messages.concat(verifier.call(model, context)) },
          options
        ]
      else
        [verifier, options]
      end
    end

    def self.bound_applicators
      @bound_applicators ||= []
    end

    # @param model generic model to validate
    # @param context context in which it would be valdiated
    # @return [Array] list of messages yielded by verifier
    def self.call(model, context = {})
      new(model).verify!(context)
    end

    # @param model generic model to validate
    def initialize(model)
      self.model = model
      self.messages = []
    end

    # @todo fix to match style guides
    # @param context context in which model would be valdiated
    # @return [Array] list of messages yielded by verifier
    def verify!(context = {})
      self.messages = []

      self.class.bound_applicators.each do |bound_applicator|
        bound_applicator.call(self, context)
      end

      messages
    end

    private

    # @abstract
    #   implement it like `super { Message.new(status, text, description) }`
    # @return new message (yield result)
    def message!(*)
      new_message = yield
      @messages << new_message
      new_message
    end
  end
end
