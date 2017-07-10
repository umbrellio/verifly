# frozen_string_literal: true

module Verifly
  # @abstract implement `#call`
  # Applies "applicable" objects to given bindings
  # (applicable objects are named based on their use,
  # currently any object is applicable).
  #
  # This class uses ClassBuilder system.
  # When reading the code, we suggest starting from '.call' method
  # @see ClassBuilder
  # @attr applicable [applicable] wrapped applicable object
  class Applicator
    # Proxy is used when applicable itself is an instance of Applicator.
    # It just delegates #call method to applicable
    # @example
    #   Applicator.call(Applicator.build(:foo), binding_, *context)
    #   # => Applicator.call(:foo, binding_, *context)
    class Proxy < self
      # @param applicable [Applicator]
      # @return Proxy if applicable is an instance of Applicator
      # @return [nil] otherwise
      def self.build_class(applicable)
        self if applicable.is_a?(Applicator)
      end

      # @param binding_ [#instance_exec] target to apply applicable
      # @param context additional info to send it to applicable
      # @return application result
      def call(binding_, *context)
        applicable.call(binding_, *context)
      end
    end

    # MethodExtractor is used when applicable is a symbol.
    # It extracts a method from binding_ and executes it on binding_
    # (so it works just like send except it sends nothing
    # when method arity is zero).
    # @example
    #   Applicator.call(Applicator.build(:foo), User.new, context)
    #   # => User.new.foo(context)
    #   # or => User.new.foo, if it does not accept context
    class MethodExtractor < self
      # @param applicable [Symbol]
      # @return MethodExtractor if applicable is a Symbol
      # @return [nil] otherwise
      def self.build_class(applicable)
        self if applicable.is_a?(Symbol)
      end

      # @param binding_ [#instance_exec] target to apply applicable to
      # @param context additional info to send to applicable
      # @return application result
      def call(binding_, *context)
        if binding_.is_a?(Binding)
          call_on_binding(binding_, *context)
        else
          invoke_lambda(binding_.method(applicable), binding_, *context)
        end
      end

      private

      # When Binding is a target, we have to respect both methods and variables
      # @param binding_ [Binding] target to apply applicable to
      # @param context additional info to send to applicable
      # @return application result
      def call_on_binding(binding_, *context)
        if binding_.local_variable_defined?(applicable)
          binding_.local_variable_get(applicable)
        else
          invoke_lambda(binding_.receiver.method(applicable), binding_, *context)
        end
      end
    end

    # InstanceEvaluator is used for strings. It works like instance_eval or
    # Binding#eval depending on binding_ class
    # @example
    #   Applicator.call('foo if context[:foo]', binding_, *context)
    #   # => foo if context[:foo]
    class InstanceEvaluator < self
      # @param applicable [String]
      # @return InstanceEvaluator if applicable is a String
      # @return [nil] otherwise
      def self.build_class(applicable)
        self if applicable.is_a?(String)
      end

      # @param binding_ [#instance_exec] target to apply applicable to
      # @param context additional info to send to applicable
      # @return application result
      def call(binding_, *context)
        if binding_.is_a?(Binding)
          binding_ = binding_.dup
          binding_.local_variable_set(:context, context)
          binding_.eval(applicable, *caller_line)
        else
          binding_.instance_eval(applicable, *caller_line)
        end
      end

      # @return [String, Integer]
      #   file and line where `Applicator.call` was called
      def caller_line
        offset = 2
        backtace_line = caller(offset..offset)[0]
        _, file, line = backtace_line.match(/\A(.+):(\d+):[^:]+\z/).to_a
        [file, Integer(line)]
      end
    end

    # ProcApplicatior is used when #to_proc is available.
    # It works not only with procs, but also with hashes etc
    # @example with a proc
    #   Applicator.call(-> { foo }, binding_, *context) # => foo
    # @example with a hash
    #   Applicator.call(Hash[foo: true], binding_, :foo) # => true
    #   Applicator.call(Hash[foo: true], binding_, :bar) # => nil
    class ProcApplicatior < self
      # @param applicable [#to_proc]
      # @return ProcApplicatior if applicable accepts #to_proc
      # @return [nil] otherwise
      def self.build_class(applicable)
        self if applicable.respond_to?(:to_proc)
      end

      # @param binding_ [#instance_exec] target to apply applicable to
      # @param context additional info to send to applicable
      # @return application result
      def call(binding_, *context)
        invoke_lambda(applicable.to_proc, binding_, *context)
      end
    end

    # Quoter is used when there is no other way to apply applicatable.
    # @example
    #   Applicator.call(true, binding_, *context) # => true
    class Quoter < self
      # @return applicable without changes
      def call(*)
        applicable
      end
    end

    extend ClassBuilder::Mixin

    self.buildable_classes =
      [Proxy, MethodExtractor, InstanceEvaluator, ProcApplicatior, Quoter]

    attr_accessor :applicable

    # Applies applicable on binding_ with context
    # @todo add @see #initialize when its todo is done
    # @param applicable [applicable]
    #   see examples in definitions of subclasses
    # @param binding_ [#instance_exec]
    #   where should applicable be applied. It could be either a generic object,
    #   where it would be `instance_exec`uted, or a binding_
    # @param context
    #   geneneric data you want to pass to applicable function.
    #   If applicable cannot accept params, context will not be sent
    # @return application result
    def self.call(applicable, binding_, *context)
      build(applicable).call(binding_, *context)
    end

    # Always use build instead of new
    # @todo add more examples right here
    # @param applicable [applicable]
    #   see examples in definitions of sublclasses
    # @api private
    def initialize(applicable)
      self.applicable = applicable
    end

    # @param [Applicator] other
    # @return [Boolean] true if applicable matches, false otherwise
    def ==(other)
      applicable == other.applicable
    end

    # @!method call(binding_, *context)
    #   @abstract
    #   Applies applicable on binding_ with context
    #   @param binding_ [#instance_exec] binding to be used for applying
    #   @param context param that will be passed if requested
    #   @return application result

    private

    # invokes lambda respecting its arity
    # @param [Proc] lambda
    # @param binding_ [#instance_exec] binding_ would be used in application
    # @param context param would be passed if lambda arity > 0
    # @return invocation result
    def invoke_lambda(lambda, binding_, *context)
      if lambda.arity.zero?
        binding_.instance_exec(&lambda)
      else
        binding_.instance_exec(*context, &lambda)
      end
    end
  end
end
