# frozen_string_literal: true

module Verifly
  # DependentCallbacks interface is similar to ActiveSupport::Callbacks, but it has few differences
  #
  # 1) `extend` it, not `include`
  #
  # 2) Use `.callback_groups` do tefine callbacks instead of define_callbacks
  #
  # 3) Better define callbacks in separate module, wich should extend DependentCallbacks::Storage
  #
  # 4) Use merge_callbacks_from(Module) instead of including it
  #
  # 5) There is no run_callbacks method.
  #
  # You can either use self.class.dependent_callbacks.invoke(group, *context) {}
  # or use .export_callbacks_to(:active_support) / .export_callbacks_to(:wrap_method)
  module DependentCallbacks
    autoload :Callback, "verifly/dependent_callbacks/callback"
    autoload :CallbackGroup, "verifly/dependent_callbacks/callback_group"
    autoload :Invoker, "verifly/dependent_callbacks/invoker"
    autoload :Service, "verifly/dependent_callbacks/service"
    autoload :Storage, "verifly/dependent_callbacks/storage"

    extend HasLogger
    include Storage

    # @api stdlib
    # Allows children to inherit callbacks from parent
    # @param [Class] child
    def inherited(child)
      super

      child.instance_exec(dependent_callbacks_service) do |service|
        @dependent_callbacks_service = Service.new(service)
      end
    end

    # Exports callbacks to another callback system / something like that
    # @param [:active_support, :wrap_method] target
    #   Target selection.
    #   * :active_support exports each group to correspoding
    #     ActiveSupport callback (via set_callback)
    #   * :wrap_method defines / redefines methods, named same as each group.
    #     If method was defined, on it's call callbacks would run around its previous defenition.
    #     If not, callbacks would run around nothing
    # @param groups [[Symbol]] arra of groups to export. Defaults to all groups
    def export_callbacks_to(target, groups: nil)
      (groups || dependent_callbacks_service.group_names).each do |group|
        case target
        when :active_support then _export_callback_group_to_active_support(group)
        when :action_controller then _export_callback_group_to_action_controller(group)
        when :wrap_method then _export_callback_group_to_method_wapper(group)
        else
          raise "#{target.inspect} export target unavailable. " \
                "available targets are :active_support, :wrap_method"
        end
      end
    end

    private

    # Exports callbacks to ActiveSupport
    # @see export_callbacks_to
    # @param group [Symbol] name of group
    def _export_callback_group_to_active_support(group)
      exports_name = :"__verifly_dependent_callbacks_exports_#{group}"

      define_method(exports_name) do |*context, &block|
        self.class.dependent_callbacks_service.invoke(group) do |invoker|
          invoker.context = context
          invoker.inner_block = block
          invoker.run(self)
        end
      end

      private(exports_name)
      set_callback(group, :around, exports_name)
    end

    # Exports callbacks to ActionController::Base
    # @see export_callbacks_to
    # @param group [Symbol] name of group
    def _export_callback_group_to_action_controller(group)
      raise unless group == :action

      around_action do |request, sequence|
        self.class.dependent_callbacks_service.invoke(group) do |invoker|
          invoker.context << request
          invoker.inner_block = sequence
          invoker.break_if { response_body }
          invoker.run(self)
        end
      end
    end

    # Exports callbacks to methods
    # @see export_callbacks_to
    # @param group [Symbol] name of group
    def _export_callback_group_to_method_wapper(group)
      instance_method = instance_method(group) rescue nil

      define_method(group) do |*args, &block|
        self.class.dependent_callbacks_service.invoke(group) do |invoker|
          invoker.around { instance_method.bind(self).call(*args, &block) if instance_method }
          invoker.context = args
          invoker.run(self)
        end
      end
    end
  end
end
