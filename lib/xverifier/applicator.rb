# frozen_string_literal: true

module XVerifier
  # @abstract implement `#call`
  class Applicator
    class Proxy < self
      def self.build_class(applicable)
        self if applicable.is_a?(Applicator)
      end

      def call(binding, context)
        applicable.call(binding, context)
      end
    end

    class MethodExtractor < self
      def self.build_class(applicable)
        self if applicable.is_a?(Symbol)
      end

      def call(binding, context)
        invoke_lambda(binding.method(applicable), binding, context)
      end
    end

    class InstanceEvaler < self
      def self.build_class(applicable)
        self if applicable.is_a?(String)
      end

      def call(binding, context)
        if binding.is_a?(Binding)
          binding = binding.dup
          binding.local_variable_set(:context, context)
          binding.eval(applicable, *caller_line)
        else
          binding.instance_eval(applicable, *caller_line)
        end
      end

      def caller_line
        _, file, line = caller(3...4)[0].match(/\A(.+):(\d+):[^:]+\z/).to_a
        [file, Integer(line)]
      end
    end

    class ProcApplicatior < self
      def self.build_class(applicable)
        self if applicable.respond_to?(:to_proc)
      end

      def call(binding, context)
        invoke_lambda(applicable.to_proc, binding, context)
      end
    end

    class Quoter < self
      def call(*)
        applicable
      end
    end

    extend ClassBuilder::Mixin

    self.buildable_classes =
      [Proxy, MethodExtractor, InstanceEvaler, ProcApplicatior, Quoter]

    attr_accessor :applicable

    def self.call(applicable, binding, context)
      build(applicable).call(binding, context)
    end

    def initialize(applicable)
      self.applicable = applicable
    end

    # @!method call(binding, context)
    #   @abstract
    #   @param binding [#instance_exec]
    #   @param context

    private

    def invoke_lambda(lambda, binding, context)
      if lambda.arity.zero?
        binding.instance_exec(&lambda)
      else
        binding.instance_exec(context, &lambda)
      end
    end
  end
end
