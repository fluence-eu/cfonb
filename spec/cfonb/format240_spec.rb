# frozen_string_literal: true

require 'cfonb'

describe CFONB::Format240 do
  describe '.parse' do
    it 'returns the sequences of the envelope' do
      sequences = described_class.parse(File.read('spec/files/format240_example.txt'))

      expect(sequences.map(&:account)).to eq(%w[00012345601 00012345602])
    end

    it 'accepts an IO' do
      sequences = File.open('spec/files/format240_example.txt') { described_class.parse(_1) }

      expect(sequences.size).to eq(2)
    end
  end
end
