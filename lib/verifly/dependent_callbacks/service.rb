# frozen_string_literal: true

module Verifly
  module DependentCallbacks
    # A service to store all callbacks info and delegate methods fom DSLs
    # @attr groups [Symbol => CallbackGroup] groups index
    # @attr parents [[Service]] parents in service inheritance system
    class Service
      attr_accessor :groups, :parents

      # @param parents [[Service]] is filled in by the parent
      def initialize(*parents)
        self.parents = parents
        self.groups = Hash.new { |h, k| h[k] = CallbackGroup.new(k) }
      end

      # Merges another service into this
      # @param other [Service]
      def merge!(other)
        parents << other
      end

      # Adds callback into matching group
      # @see Callback#initialize
      # @param position [:before, :after, :around]
      # @param group [Symbol] group name
      # @param args callback args
      def add_callback(position, group, *args, &block)
        groups[group].add_callback(Callback.new(position, *args, &block))
      end

      def invoke(group_name)
        invoker = Invoker.new(compiled_group(group_name))
        yield(invoker)
      end

      # @return [[Symbol]] names of all groups stored inside itself or parents
      def group_names
        [groups.keys, *parents.map(&:group_names)].flatten.uniq
      end

      # Compiles callback group from itself and parents callback groups.
      # If nothing changed, cached value taken
      # @param group_name [Symbol] group name
      # @return [CallbackGroup] callback group joined from all relative callback groups
      def compiled_group(group_name)
        @compiled_groups_cache ||= Hash.new { |h, k| h[k] = {} }
        cache_entry = @compiled_groups_cache[group_name]
        return cache_entry[:group] if cache_entry[:digest] == digest

        cache_entry[:digest] = digest
        cache_entry[:group] = parents.map { |parent| parent.compiled_group(group_name) }
                                     .reduce(groups[group_name], &:merge)
      end

      # Digest change forces recompilation of compiled_group
      # @return [Numeric]
      def digest
        [
          *parents.map(&:digest),
          *groups.map { |k, v| [k, v.digest].join },
        ].hash
      end

      # Exprorts selected group to graphiz .dot format
      def to_dot(group, binding_)
        compiled_group(group).to_dot(binding_)
      end
    end
  end
end
