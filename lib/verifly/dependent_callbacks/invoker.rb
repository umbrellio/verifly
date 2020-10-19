# frozen_string_literal: true

require "benchmark"

module Verifly
  module DependentCallbacks
    # Simple service to invoke callback groups
    # @example simple invokation
    #   def invoke_callbacks
    #     Invoker.new(group) do |invoker|
    #       invoker.around {}
    #       invoker.run(self)
    #     end
    #   end
    # @see DependentCallbacks#export_callbacks_to
    # @!attribute flat_sequence
    #   @return [[Callback]] tsorted callbacks
    # @!attribute context
    #   @return [[Object]] invokation context. It would be passed to all applicators
    # @!attribute inner_block
    #   @return [Proc] block in the middle of middleware
    # @!visibility private
    # @!attribute break_if_proc
    #   @note does not affect 'after' callbacks
    #   @return [Proc] if this block evaluate to truthy, sequence would be halted.
    # @!attribute binding_
    #   @return [#instance_exec] binding_ to evaluate on
    class Invoker
      attr_accessor :flat_sequence, :context, :inner_block

      # @param callback_group [CallbackGroup]
      # @yield self if block given
      def initialize(callback_group)
        self.flat_sequence = callback_group.sequence
        self.context = []
        self.break_if_proc = proc { false }
        yield(self) if block_given?
      end

      # @yield in the middle of middleware, setting inner_block attribute
      # @see inner_block
      def around(&block)
        self.inner_block = block
      end

      # @yield between callbacks halting chain if evaluated to true
      # @see break_if_proc
      def break_if(&block)
        self.break_if_proc = block
      end

      # Sets binding_, reduces callbacks into big proc and evaluates it
      # @param binding_ [#instance_exec] binding_ to be evaluated on
      # @return inner_block call result
      def run(binding_)
        self.binding_ = binding_
        result = nil
        block_with_result_extractor = -> { result = inner_block&.call }

        log!(:info, "Started chain processing")

        sequence =
          flat_sequence.reverse_each.reduce(block_with_result_extractor) do |sequence, callback|
            -> { call_callback(callback, sequence) }
          end

        sequence.call
        result
      end

      private

      attr_accessor :break_if_proc, :binding_

      # Invokes callback in context of invoker
      # @param callback [Callback] current callbacks
      # @param sequence [Proc] already built sequence of callbacks
      def call_callback(callback, sequence)
        log!(:debug, "Invokation", callback: callback)

        case callback.position
        when :before then call_callback_before(callback, sequence)
        when :after then call_callback_after(callback, sequence)
        when :around then call_callback_around(callback, sequence)
        end

        nil
      end

      # Invokes before_<name> callbacks
      # @param callback [Callback] current callbacks
      # @param sequence [Proc] already built sequence of callbacks
      def call_callback_before(callback, sequence)
        call_with_time_report!(callback, binding_, *context)

        if break_if_proc.call(*context)
          log!(:warn, "Chain halted", callback: callback)
        else
          sequence.call
        end
      end

      # Invokes after_<name> callbacks
      # @param callback [Callback] current callbacks
      # @param sequence [Proc] already built sequence of callbacks
      def call_callback_after(callback, sequence)
        sequence.call
        call_with_time_report!(callback, binding_, *context)
      end

      # Invokes around_<name> callbacks
      # @param callback [Callback] current callbacks
      # @param sequence [Proc] already built sequence of callbacks
      def call_callback_around(callback, sequence)
        inner_executed = false
        inner = lambda do
          inner_executed = true
          if break_if_proc.call(*context)
            log!(:warn, "Chain halted", callback: callback)
          else
            sequence.call
          end
        end

        call_with_time_report!(callback, binding_, inner, *context)

        unless inner_executed
          log!(:warn, "Chain halted (sequential block not called)", callback: callback)
        end
      end

      # Logger interface to decorate messages. Uses DependentCallbacks.logger
      # @param severity [:debug, :info, :warn, :error, :fatal] severity level
      # @param message [String] message
      # @param callback [Callback?] callback to get extra context
      def log!(severity, message, callback: nil)
        DependentCallbacks.logger.public_send(severity, "Verifly::DependentCallbacks::Invoker") do
          if callback
            <<~TXT.squish if callback
              #{message} callback #{callback.name || "(anonymous)"}
                         in #{callback.action.source_location(binding_)&.join(':')}
            TXT
          else
            message
          end
        end
      end

      def call_with_time_report!(callback, *args) # :nodoc:
        time_in_ms = Benchmark.realtime { callback.call(*args) } * 1000
        log!(:info, "Run in #{time_in_ms.round(1)}ms", callback: callback)
      end
    end
  end
end
