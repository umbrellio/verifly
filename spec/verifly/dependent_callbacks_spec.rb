# frozen_string_literal: true

describe Verifly::DependentCallbacks do
  subject(:klass) do
    Class.new do
      extend Verifly::DependentCallbacks

      callback_groups :action
      attr_accessor :flags

      def initialize
        self.flags = []
      end
    end
  end

  specify "integration" do # rubocop:disable RSpec/ExampleLength
    klass.class_exec do
      module CallbacksModule
        extend Verifly::DependentCallbacks::Storage

        callback_groups :action

        before_action -> {}, require: %i[foo bar], name: :basic_setup
        around_action :foo, require: :bar
        before_action :bar

        before_action :baz, require: :basic_setup

        before_action :bat, insert_before: :foo

        def foo(sequence)
          set_flags!(:foo)

          sequence.call { set_flags!(:yolo) }

          set_flags!(:foo_after)
        end

        def bar
          set_flags!(:bar)
        end

        def baz
          set_flags!(:baz)
        end

        def bat
          set_flags!(:bat)
        end
      end

      extend Verifly::DependentCallbacks
      merge_callbacks_from(CallbacksModule)

      def initialize
        self.flags = {}
      end

      def set_flags!(name)
        all_flags = %i[foo bar baz bat action]

        flags[name] = (all_flags - [name]).each_with_object(invoked: true) do |x, o|
          o[x] = !!flags[x]
        end

        flags
      end

      def action
        set_flags!(:action)
      end

      export_callbacks_to(:wrap_method) # wrap #action with callbacks
    end

    expect(klass.new.action).to match(
      action: match(invoked: true, foo: true, bar: true, baz: true, bat: true),
      bar: match(invoked: true, foo: anything, baz: anything, bat: anything, action: false),
      bat: match(invoked: true, foo: false, bar: anything, baz: anything, action: false),
      baz: match(invoked: true, foo: true, bar: true, bat: anything, action: false),
      foo: match(invoked: true, bar: true, baz: anything, bat: anything, action: false),
      foo_after: match(invoked: true, foo: true, bar: true, baz: true, bat: true, action: true),
    )
  end

  specify "inhreritance" do
    klass.class_exec do
      before_action { flags << :parent }

      def action
        flags << :action
      end

      export_callbacks_to(:wrap_method) # wrap #action with callbacks
    end

    child1 = Class.new(klass) { before_action { flags << :child1 } }
    child2 = Class.new(klass) { before_action { flags << :child2 } }

    expect(child1.new.action).to match_array %i[parent child1 action]
    expect(child2.new.action).to match_array %i[parent child2 action]
  end

  describe "#export_callbacks_to" do
    # wrap_method tested via specify "integration"

    specify "unknown method" do
      expect { klass.export_callbacks_to(:unknown_method) }
        .to raise_error ":unknown_method export target unavailable. " \
                        "available targets are :active_support, :wrap_method"
    end

    specify "active_support" do
      require "active_support"

      klass.class_exec do
        include ActiveSupport::Callbacks
        before_action -> { flags << :before }
        define_callbacks :action
        export_callbacks_to(:active_support)

        def action
          run_callbacks(:action) { flags << :action }
        end
      end

      expect(klass.new.action).to eq %i[before action]
    end
  end
end
