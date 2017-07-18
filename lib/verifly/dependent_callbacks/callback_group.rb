# frozen_string_literal: true

require "tsort"

module Verifly
  module DependentCallbacks
    # Handles callbacks with same 'group' option, allowing to do sequential invokation of them
    # @attr name [Symbol] name of callback group
    # @attr index [{Symbol => Callback}] index for named callback lookup
    # @attr list [[Callback]] all callbacks
    class CallbackGroup
      # Implements topoplogy sorting of callbacks.
      # As far as CallbackGroup is designed to store Callbacks, it is unable to link them into
      # graph immediately . Service can do it, because if some callbacks are missing on
      # compilation stage, there should be an error
      # @see http://ruby-doc.org/stdlib-2.3.4/libdoc/tsort/rdoc/TSort.html
      # @attr dependencies [{ Callback => Callback }] dependency graph
      class TSortService
        include TSort

        attr_accessor :dependencies

        # @param callback_group [CallbackGroup] group to be tsorted
        # @return [[Callback]] tsorted callbacks array (aka sequence)
        def self.call(callback_group)
          new(callback_group).tsort
        end

        # @param callback_group [CallbackGroup] group to be tsorted
        def initialize(callback_group)
          self.dependencies = Hash.new { |h, k| h[k] = Set[] }

          callback_group.list.each do |callback|
            dependencies[callback] ||= []

            callback.before.each do |key|
              dependencies[callback_group.index.fetch(key)] << callback
            end

            callback.after.each do |key|
              dependencies[callback] << callback_group.index.fetch(key)
            end
          end
        end

        private

        # @api stdlib
        # @see TSort
        def tsort_each_node(&block)
          dependencies.keys.each(&block)
        end

        # @api stdlib
        # @see TSort
        def tsort_each_child(node, &block)
          dependencies[node].each(&block)
        end
      end

      attr_accessor :index, :list, :name

      # @param name [Symbol] name of callback group
      # @yield self if block given
      def initialize(name)
        self.name = name
        self.index = {}
        self.list = []

        yield(self) if block_given?
      end

      # Adds callback to list and index, reset sequence
      # @param callback [Callback] new callback
      def add_callback(callback)
        list << callback
        index[callback.name] = callback if callback.name

        @sequence = nil
      end

      # Merges with another group
      # @param other [CallbackGroup]
      # @raise if group names differ
      def merge(other)
        raise "Only groups with one name could be merged" unless name == other.name

        [*list, *other.list].each_with_object(CallbackGroup.new(name)) do |callback, group|
          group.add_callback(callback)
        end
      end

      # Memoizes tsorted graph
      # @return [[Callback]]
      def sequence
        @sequence ||= TSortService.call(self)
      end

      # Digest change forces recompilation of callback group in service
      # @return [Numeric]
      def digest
        [name, list].hash
      end

      # Renders graphviz dot-representation of callback group
      # @return graphviz dot
      def to_dot(binding_)
        template_path = File.expand_path("callback_group.dot.erb", __dir__)
        erb = ERB.new(File.read(template_path))
        erb.filename = template_path
        erb.result(binding)
      end
    end
  end
end
