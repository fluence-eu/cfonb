# frozen_string_literal: true

require 'cfonb'

describe CFONB::LineParser::SequenceDetail do
  describe '.initialize' do
    subject(:line) { described_class.new(input) }

    let(:input) { File.read('spec/files/sequences.txt').lines[4].chomp }

    it 'correctly parses a line' do
      expect(line).to have_attributes(
        'code' => '35',
        'sequence_number' => '000003',
        'body' => input,
      )
    end
  end
end
