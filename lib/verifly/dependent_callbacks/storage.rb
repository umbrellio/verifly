# frozen_string_literal: true

module Verifly
  module DependentCallbacks
    # Subset of DependentCallbacks dsl methods, which could be used in callbacks storage
    module Storage
      # Declares callback groups with given names. This creates before_ after_ and around_
      # signleton methods for each group given
      # @see Service#add_callback
      # @param groups [[Symbol]]
      def callback_groups(*groups)
        groups.each do |group|
          dependent_callbacks_service.groups[group] # Creates an empty group

          %i[before after around].each do |position|
            define_singleton_method("#{position}_#{group}") do |*args, &block|
              dependent_callbacks_service.add_callback(position, group, *args, &block)
            end
          end
        end
      end

      # Merges all callbacks from given storage
      # @param storage [Module { extend Storage }]
      def merge_callbacks_from(storage)
        include(storage)
        dependent_callbacks_service.merge!(storage.dependent_callbacks_service)
      end

      # @return [Service] associated with current Class / Module
      def dependent_callbacks_service
        @dependent_callbacks_service ||= Service.new
      end
    end
  end
end
