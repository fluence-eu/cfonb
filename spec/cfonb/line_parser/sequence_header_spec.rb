# frozen_string_literal: true

require 'cfonb'

describe CFONB::LineParser::SequenceHeader do
  describe '.initialize' do
    subject(:line) { described_class.new(input) }

    let(:input) { File.read('spec/files/sequences.txt').lines[2].chomp }

    it 'correctly parses a line' do
      expect(line).to have_attributes(
        'code' => '31',
        'sequence_number' => '000001',
        'operation_code' => 'CD',
        'previous_file_date' => '290926',
        'currency_indicator' => 'E',
        'scale' => 2,
        'currency' => 'EUR',
        'bank' => '12345',
        'branch' => '00001',
        'account' => '00012345602',
        'holder_name' => 'ACME SERVICES',
        'body' => input,
      )
    end

    context 'without currency' do
      let(:input) { File.read('spec/files/sequences.txt').lines[0].chomp }

      it 'leaves scale and currency empty' do
        expect(line).to have_attributes('scale' => nil, 'currency' => nil)
      end
    end
  end
end
