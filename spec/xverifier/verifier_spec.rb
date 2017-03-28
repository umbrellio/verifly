# frozen_string_literal: true

describe XVerifier::Verifier do
  let(:model) { double(:model) }

  subject(:verifier) do
    Class.new(described_class) do
      def message!(*args)
        super { args }
      end
    end
  end

  describe 'verifiers conditioning' do
    let(:context) { Hash[foo: true] }

    def mark(name)
      -> { message!(name) }
    end

    specify 'if' do
      verifier.verify mark(:foo), if: ->(context) { context[:foo] }
      verifier.verify mark(:bar), if: ->(context) { context[:bar] }
      verifier.verify mark(:baz)

      expect(verifier.call(model, context)).to eq [%i(foo), %i(baz)]
    end

    specify 'unless' do
      verifier.verify mark(:foo), unless: ->(context) { context[:foo] }
      verifier.verify mark(:bar), unless: ->(context) { context[:bar] }
      verifier.verify mark(:baz)

      expect(verifier.call(model, context)).to eq [%i(bar), %i(baz)]
    end
  end

  describe 'verifiers invocation' do
    let(:context) { double(:context) }

    specify 'with subclass' do
      subclass = Class.new(verifier)
      subclass.verify { |context| message!(context) }
      verifier.verify(subclass)
      expect(verifier.call(model, context)).to eq [[context]]
    end

    specify 'with block' do
      verifier.verify { |context| message!(context) }
      expect(verifier.call(model, context)).to eq [[context]]
    end

    context 'with proc' do
      specify 'arity = 1' do
        verifier.verify ->(context) { message!(context) }
        expect(verifier.call(model, context)).to eq [[context]]
      end

      specify 'arity = 0' do
        verifier.verify -> { message!(model) }
        expect(verifier.call(model, context)).to eq [[model]]
      end
    end

    specify 'with #to_proc' do
      verifier.verify -> { message!(model) }, if: Hash[context => true]
      expect(verifier.call(model, context)).to eq [[model]]
      expect(verifier.call(model, double(:new_context))).to be_empty
    end

    specify 'with string' do
      verifier.verify 'message!(context)'
      expect(verifier.call(model, context)).to eq [[context]]
    end

    specify 'with symbol' do
      verifier.send(:define_method, :foo) { |context = {}| message!(context) }
      verifier.verify :foo
      expect(verifier.call(model, context)).to eq [[context]]
    end
  end
end
