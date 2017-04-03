# frozen_string_literal: true

describe Verifly::ClassBuilder do
  let(:klass) do
    # This extend is used in all specs for class_double purposes.
    # You are not forced to extend mixin if you implement `.build_class`
    # in all `klasses`
    Class.new { extend Verifly::ClassBuilder::Mixin }
  end

  let(:unbuildable) { class_double(klass, build_class: nil) }
  let(:recursive) { class_double(klass, build_class: buildable) }
  let(:buildable) { class_double(klass) }

  describe 'Verifly::ClassBuilder flow' do
    subject(:class_builder) { described_class.new([unbuildable, recursive]) }

    its(:call) { is_expected.to eq buildable }
  end

  specify 'Verifly::ClassBuilder::Mixin#build_class' do
    klass.buildable_classes = [unbuildable, recursive]
    expect(klass.build_class).to eq(buildable)
  end
end
