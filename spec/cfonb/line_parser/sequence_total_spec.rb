# frozen_string_literal: true

require 'cfonb'

describe CFONB::LineParser::SequenceTotal do
  describe '.initialize' do
    subject(:line) { described_class.new(input) }

    let(:input) { File.read('spec/files/sequences.txt').lines[6].chomp }

    it 'correctly parses a line' do
      expect(line).to have_attributes(
        'code' => '39',
        'sequence_number' => '000005',
        'operation_code' => 'CD',
        'date' => Date.new(2026, 9, 30),
        'bank' => '12345',
        'branch' => '00001',
        'account' => '00012345602',
        'holder_name' => 'ACME SERVICES',
        'amount' => 123_456,
        'body' => input,
      )
    end

    context 'with a blank amount' do
      let(:input) { File.read('spec/files/sequences.txt').lines[1].chomp }

      it 'leaves the amount empty' do
        expect(line.amount).to be_nil
      end
    end

    context 'with a non numeric amount' do
      let(:input) { File.read('spec/files/sequences_invalid_amount.txt').lines[1].chomp }

      it 'raises a ParserError' do
        expect { line }.to raise_error(CFONB::ParserError, "Invalid amount '00000012345A'")
      end
    end
  end
end
