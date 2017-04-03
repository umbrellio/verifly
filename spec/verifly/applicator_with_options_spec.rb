# frozen_string_literal: true

describe Verifly::ApplicatorWithOptions do
  subject(:applicator_with_options) do
    described_class.new(action, if: if_condition, unless: unless_condition)
  end

  let(:action) { instance_double(Object, :action) }
  let(:if_condition) { true }
  let(:unless_condition) { false }

  let(:binding_) { instance_double(Object, :binding) }
  let(:context) { instance_double(Object, :context) }

  describe 'default values' do
    subject { described_class.new(action) }

    its(:if_condition) { is_expected.to eq applicator(true) }
    its(:unless_condition) { is_expected.to eq applicator(false) }
  end

  shared_examples 'it does not call action' do
    it 'does not call action' do
      expect(applicator_with_options.action).not_to receive(:call)
      applicator_with_options.call(binding_, context)
    end
  end

  it 'calls action' do
    expect(applicator_with_options.action)
      .to receive(:call).with(binding_, context)
    applicator_with_options.call(binding_, context)
  end

  context 'if condition resolves to falsey' do
    let(:if_condition) { -> { false } }

    it_behaves_like 'it does not call action'
  end

  context 'unless condition resolves to truthy' do
    let(:unless_condition) { -> { true } }

    it_behaves_like 'it does not call action'
  end
end
