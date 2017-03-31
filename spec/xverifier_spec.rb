# frozen_string_literal: true

describe XVerifier do
  describe 'VERSION' do
    it 'is well-formated' do
      expect(XVerifier::VERSION).to match(/\A0\.\d+\.\d+\.\d+(_.+)?\z/)
    end

    it 'is released' do
      pending 'WIP'
      expect(XVerifier::VERSION).to match(/\A\d+\.\d+\.\d+(_.+)?\z/)
    end
  end
end
