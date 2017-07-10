# frozen_string_literal: true

describe Verifly::Verifier do
  subject(:verifier) do
    Class.new(described_class) do
      def message!(*args)
        super { args }
      end
    end
  end

  let(:model) { instance_double(Object, :model) }

  describe "verifiers conditioning" do
    let(:context) { Hash[foo: true] }

    def mark(name)
      -> { message!(name) }
    end

    specify "if" do
      verifier.verify mark(:foo), if: -> (context) { context[:foo] }
      verifier.verify mark(:bar), if: -> (context) { context[:bar] }
      verifier.verify mark(:baz)

      expect(verifier.call(model, context)).to eq [%i[foo], %i[baz]]
    end

    specify "unless" do
      verifier.verify mark(:foo), unless: -> (context) { context[:foo] }
      verifier.verify mark(:bar), unless: -> (context) { context[:bar] }
      verifier.verify mark(:baz)

      expect(verifier.call(model, context)).to eq [%i[bar], %i[baz]]
    end
  end

  describe "verifiers invocation" do
    let(:context) { instance_double(Object, :context) }

    specify "with subclass" do
      subclass = Class.new(verifier)
      subclass.verify { |context| message!(context) }
      verifier.verify_with(subclass)
      expect(verifier.call(model, context)).to eq [[context]]
    end

    specify "with block" do
      verifier.verify { |context| message!(context) }
      expect(verifier.call(model, context)).to eq [[context]]
    end

    context "with proc" do
      specify "arity = 1" do
        verifier.verify -> (context) { message!(context) }
        expect(verifier.call(model, context)).to eq [[context]]
      end

      specify "arity = 0" do
        verifier.verify -> { message!(model) }
        expect(verifier.call(model, context)).to eq [[model]]
      end
    end

    context "with #to_proc" do
      before do
        verifier.verify -> { message!(model) }, if: Hash[context => true]
      end

      context "with same context" do
        it { expect(verifier.call(model, context)).to eq [[model]] }
      end

      context "with different contextes" do
        let(:new_context) { instance_double(Object, :new_context) }

        it { expect(verifier.call(model, new_context)).to be_empty }
      end
    end

    specify "with string" do
      verifier.verify "message!(context[0])"
      expect(verifier.call(model, context)).to eq [[context]]
    end

    specify "with symbol" do
      verifier.send(:define_method, :foo) { |context = {}| message!(context) }
      verifier.verify :foo
      expect(verifier.call(model, context)).to eq [[context]]
    end
  end
end
