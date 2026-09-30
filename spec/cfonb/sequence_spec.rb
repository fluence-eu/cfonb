# frozen_string_literal: true

require 'cfonb'

describe CFONB::Sequence do
  subject(:sequence) do
    described_class.new(CFONB::LineParser.parse(lines[0]))
      .tap { _1.details << CFONB::LineParser::SequenceDetail.new(lines[1]) }
      .tap { _1.merge_total(CFONB::LineParser.parse(lines[2])) }
  end

  let(:lines) { File.read('spec/files/sequences.txt').lines.map(&:chomp).values_at(2, 3, 6) }

  describe '#raw' do
    it 'joins the header, details and total lines' do
      expect(sequence.raw).to eq(lines.join("\n"))
    end
  end

  describe '#rib' do
    it 'returns the correct rib' do
      expect(sequence.rib).to eq('12345000010001234560224')
    end
  end

  describe '#iban' do
    it 'returns the correct iban' do
      expect(sequence.iban).to eq('FR7612345000010001234560224')
    end
  end
end
