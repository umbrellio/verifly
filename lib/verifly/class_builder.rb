# frozen_string_literal: true

module Verifly
  # ClassBuilder is similar to Uber::Builder, but it
  # allows child classes to decide whether they will be used.
  # I find it much more object-oriented
  # @attr klasses [Array(Class)]
  #   classes to iterate during search of most suitable
  class ClassBuilder
    # Mixin provides useful methods to integrate into builder subsystem.
    # Feel free to override or just never include it.
    # @attr_writer [Array(Class)] buildable_classes
    #   Array of classes which will be checked if they
    #   suite constructor arguments. Order matters
    module Mixin
      # Array of classes which will be checked if they
      # suite constructor arguments. Order matters
      # @param klasses [Array(Class)]
      def buildable_classes=(klasses)
        @class_builder = ClassBuilder.new(klasses).freeze
      end

      # Default implementation of build_class.
      # Feel free to change it, but you'll have to override it in
      # buildable_classes
      def build_class(*args, &block)
        if @class_builder
          @class_builder.call(*args, &block)
        else
          self
        end
      end

      # Default implementation.
      # This method should be used instead of new in all cases
      def build(*arguments, &block)
        build_class(*arguments, &block).new(*arguments, &block)
      end
    end

    attr_accessor :klasses

    # @param klasses [Array(Classes)]
    def initialize(klasses)
      self.klasses = klasses
    end

    # @return [Class] first nonzero class returned by .build_class
    def call(*arguments, &block)
      klasses.each do |klass|
        result = klass.build_class(*arguments, &block)
        return result if result
      end
    end
  end
end
