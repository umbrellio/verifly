# frozen_string_literal: true

module XVerifier
  # @abstract implement `#call`
  # Applicates objects called `applicable`
  # (all objects are applicable, this typing made for usage purposes).
  #
  # This class uses ClassBuilder subsystem, start with .call method
  # @see ClassBuilder
  # @attr applicable [applicable] wrapped applicable object
  class Applicator
    # Proxy is used when applicable itself is an Applicator.
    # It just delegates #call to it
    # @example
    #   Applicator.call(Applicator.build(:foo), binding, context)
    #   # => Applicator.call(:foo, binding, context)
    class Proxy < self
      # @param applicable [Applicator]
      # @return Proxy if applicable is Applicator
      # @return [nil] otherwise
      def self.build_class(applicable)
        self if applicable.is_a?(Applicator)
      end

      # @param binding [#instance_exec] target to applicate applicable
      # @param context additional info to send it to applicable
      # @return application result
      def call(binding, context)
        applicable.call(binding, context)
      end
    end

    # MethodExtractor is used when applicable is a symbol.
    # It extracts extracts method from binding and executes it on binding
    # (so it works just like send except it sends nothing
    # when method arity is zero).
    # @example
    #   Applicator.call(Applicator.build(:foo), User.new, context)
    #   # => User.new.foo(context)
    #   # or => User.new.foo, if it does not accept context
    class MethodExtractor < self
      # @param applicable [Symbol]
      # @return MethodExtractor if applicable is Symbol
      # @return [nil] otherwise
      def self.build_class(applicable)
        self if applicable.is_a?(Symbol)
      end

      # @param binding [#instance_exec] target to applicate applicable
      # @param context additional info to send it to applicable
      # @return application result
      def call(binding, context)
        invoke_lambda(binding.method(applicable), binding, context)
      end
    end

    # InstanceEvaluator is used for string. It works like instance_eval or
    # Binding#eval depending on binding class
    # @example
    #   Applicator.call('foo if context[:foo]', binding, context)
    #   # => foo if context[:foo]
    class InstanceEvaluator < self
      # @param applicable [String]
      # @return InstanceEvaluator if applicable is String
      # @return [nil] otherwise
      def self.build_class(applicable)
        self if applicable.is_a?(String)
      end

      # @param binding [#instance_exec] target to applicate applicable
      # @param context additional info to send it to applicable
      # @return application result
      def call(binding, context)
        if binding.is_a?(Binding)
          binding = binding.dup
          binding.local_variable_set(:context, context)
          binding.eval(applicable, *caller_line)
        else
          binding.instance_eval(applicable, *caller_line)
        end
      end

      # @return [String, Integer] file and line where `Applicator.call` called
      def caller_line
        _, file, line = caller(3...4)[0].match(/\A(.+):(\d+):[^:]+\z/).to_a
        [file, Integer(line)]
      end
    end

    # ProcApplicatior is used when #to_proc is available.
    # It works not just with procs, but also with hashes etc
    # @example with proc
    #   Applicator.call(-> { foo }, binding, context) # => foo
    # @example with hash
    #   Applicator.call(Hash[foo: true], binding, :foo) # => true
    #   Applicator.call(Hash[foo: true], binding, :bar) # => nil
    class ProcApplicatior < self
      # @param applicable [#to_proc]
      # @return ProcApplicatior if applicable accepts #to_proc
      # @return [nil] otherwise
      def self.build_class(applicable)
        self if applicable.respond_to?(:to_proc)
      end

      # @param binding [#instance_exec] target to applicate applicable
      # @param context additional info to send it to applicable
      # @return application result
      def call(binding, context)
        invoke_lambda(applicable.to_proc, binding, context)
      end
    end

    # Quoter is used when there is no other way to applicate applicatable.
    # @example
    #   Applicator.call(true, binding, context) # => true
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

    # Applicates applicable on binding with context
    # @todo add @see #initialize when it's todo done
    # @param applicable [applicable]
    #   see examples in sublcasses defenitions
    # @param binding [#instance_exec]
    #   where should applicable be applied. It could be either a generic object,
    #   where it would be `instance_exec`uted, or a binding
    # @param context
    #   geneneric data you want to pass to applicable function.
    #   If applicable would not accept params, it would not be sent
    # @return application result
    def self.call(applicable, binding, context)
      build(applicable).call(binding, context)
    end

    # Always use build instead of new
    # @todo add more examples right here
    # @param applicable [applicable]
    #   see examples in sublcasses defenitions
    # @api private
    def initialize(applicable)
      self.applicable = applicable
    end

    # @!method call(binding, context)
    #   @abstract
    #   Applicates applicable on binding with context
    #   @param binding [#instance_exec] biding would be used in application
    #   @param context param would be passed if requested
    #   @return application result

    private

    # invokes lambda basing on it's arity
    # @param [Proc] lambda
    # @param binding [#instance_exec] binding would be used in application
    # @param context param would be passed if lambda arity > 0
    # @return invokation result
    def invoke_lambda(lambda, binding, context)
      if lambda.arity.zero?
        binding.instance_exec(&lambda)
      else
        binding.instance_exec(context, &lambda)
      end
    end
  end
end