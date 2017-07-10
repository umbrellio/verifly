# frozen_string_literal: true

module Verifly
  # Verifier is a proto-validator class, which allows to
  # use generic messages formats (instead of errors, which are raw text)
  # @abstract
  #   implement `#message!` method in terms of super
  # @attr model
  #   Generic object to be verified
  # @attr messages [Array]
  #   Array with all messages yielded by the verifier
  class Verifier
    autoload :ApplicatorWithOptionsBuilder,
             "verifly/verifier/applicator_with_options_builder"

    attr_accessor :model, :messages

    # @!method self.verify(action = block, options = {}, &block)
    # @example with a block
    #   verify { |context| message!() if context[:foo] }
    # @example with a proc
    #   verify -> (context) { message!() if context[:foo] }
    # @example with a hash
    #  verify -> { message!() } if: { foo: true }
    # @example context can be provided as a lambda param
    #   verify -> { message!() }, if: -> (context) { context[:foo] }
    # @example with a symbol
    #   verify :foo, if: :bar
    #   # calls #foo if #bar is true
    #   # bar can accept context if desired
    # @example with a string
    #  verify 'message!() if context[:foo]'
    #  verify 'message!()', if: 'context[:foo]'
    # @param action [#to_proc|Symbol|String|nil]
    #   verifier defenition, see examples
    # @option options [#to_proc|Symbol|String|nil] if (true)
    #   call verifier only if block invocation result is truthy
    # @option options [#to_proc|Symbol|String|nil] unless (false)
    #   call verifier only if block invocation result is falsey
    # @yield [context] yields on `#verfify!` calls
    # @raise [ArgumentError] if there is more than two arguments and block
    # @raise [ArgumentError] if there is zero arguments and no block
    # @return [Array] list of all defined verifiers
    def self.verify(*args, &block)
      bound_applicators << ApplicatorWithOptions.new(*args, &block)
    end

    # Calls DescendantClass.call(model, context) and merges its messages.
    # DescendantClass should be a descendant of current class
    # @param name [String, Class]
    #   name of descendant class or descendant class itself
    # @option options [#to_proc|Symbol|String|nil] if (true)
    #   call verifier if only block invocation result is truthy
    # @option options [#to_proc|Symbol|String|nil] unless (false)
    #   call verifier if only block invocation result is falsey
    # @return [Array] list of all verifiers already defined
    def self.verify_with(name, options = {})
      verify(options) do |context|
        verifier = name.is_a?(String) ? Object.const_get(name, false) : name
        raise ArgumentError, <<~ERROR unless verifier < self.class
          Nested verifiers should be inherited from verifier they nested are in
        ERROR

        messages.concat(verifier.call(model, context))
      end
    end

    # @return [[ApplicatorWithOptions]]
    #   List of applicators, bound by .verify
    def self.bound_applicators
      @bound_applicators ||= []
    end

    # @param model generic model to validate
    # @param context context in which it is valdiated
    # @return [Array] list of messages yielded by the verifier
    def self.call(model, context = {})
      new(model).verify!(context)
    end

    # @param model generic model to validate
    def initialize(model)
      self.model = model
      self.messages = []
    end

    # @param context context in which model is valdiated
    # @return [Array] list of messages yielded by the verifier
    def verify!(context = {})
      self.messages = []

      self.class.bound_applicators.each do |bound_applicator|
        bound_applicator.call(self, context)
      end

      messages
    end

    private

    # @abstract
    #   implementation example:
    #   `super { Message.new(status, text, description) }`
    # @return new message (yield result)
    def message!(*)
      new_message = yield
      @messages << new_message
      new_message
    end
  end
end
