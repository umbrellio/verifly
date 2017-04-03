# frozen_string_literal: true

describe XVerifier::Applicator do
  subject(:applicator) { described_class.build(applicable) }

  let(:binding_class) do
    # defining #foo to use it with `instance_double`s
    Class.new { define_method(:foo) { |*| } }
  end

  let(:binding_) { instance_double(binding_class, :binding, foo: result) }
  let(:context) { instance_double(Object, :context) }
  let(:result) { instance_double(Object, :result) }

  shared_context 'call(context, binding_)' do
    subject(:call!) { applicator.call(binding_, context) }
  end

  shared_examples 'its call returns result' do
    describe 'call(context, binding_)' do
      include_context 'call(context, binding_)'
      it { is_expected.to eq(result) }
    end
  end

  context 'Proxy' do
    let(:applicable) { described_class.build(result) }

    it { is_expected.to be_a XVerifier::Applicator::Proxy }
    it_behaves_like 'its call returns result'
  end

  context 'MethodExtractor' do
    let(:applicable) { :foo }

    it { is_expected.to be_a XVerifier::Applicator::MethodExtractor }

    describe 'call(context, binding_)' do
      include_context 'call(context, binding_)'

      context 'method on generic object' do
        before do
          expect(binding_).to receive(:foo).with(context).and_return(result)
        end

        it { is_expected.to eq(result) }
      end

      context 'method on binding' do
        let(:binding_) { binding }
        let(:applicable) { :result }

        it { is_expected.to eq(result) }
      end

      context 'variable on binding' do
        let(:binding_) do
          foo = result
          binding
        end

        it { is_expected.to eq(result) }
      end
    end
  end

  context 'InstanceEvaluator' do
    let(:applicable) { 'foo' }

    it { is_expected.to be_a XVerifier::Applicator::InstanceEvaluator }

    describe 'call(context, binding_)' do
      shared_examples 'error backtrace points to this file' do
        subject(:error) do
          begin
            call!
          rescue => e
            e
          else
            raise 'No error raised'
          end
        end

        let(:applicable) { 'raise' }

        its(:backtrace) do
          expect(error.backtrace[0]).to include(__FILE__)
        end
      end

      include_context 'call(context, binding_)'
      it_behaves_like 'error backtrace points to this file'
      it { is_expected.to eq(result) }

      context 'when applicable = context' do
        let(:applicable) { 'context' }

        it { is_expected.to eq(context) }
      end

      context 'when binding_ is a Binding' do
        let(:binding_) { binding }
        let(:applicable) { '[result, context]' }

        it_behaves_like 'error backtrace points to this file'
        it { is_expected.to eq [result, context] }

        context 'when binding_ does not have "context"' do
          let(:binding_) { Object.new.send(:binding) }
          let(:applicable) { 'context' }

          it { is_expected.to eq(context) }
        end
      end
    end
  end

  context 'ProcApplicatior' do
    let(:applicable) { -> { foo } }

    it { is_expected.to be_a XVerifier::Applicator::ProcApplicatior }

    describe 'call(context, binding_)' do
      include_context 'call(context, binding_)'
      it { is_expected.to eq(result) }

      context 'when applicable requests arg' do
        let(:applicable) { ->(context) { [foo, context] } }

        it { is_expected.to eq [result, context] }
      end
    end
  end

  context 'Quoter' do
    let(:applicable) { result }

    it { is_expected.to be_a XVerifier::Applicator::Quoter }
    it_behaves_like 'its call returns result'
  end
end
