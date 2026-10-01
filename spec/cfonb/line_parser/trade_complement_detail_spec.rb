# frozen_string_literal: true

require 'cfonb'

describe CFONB::LineParser::TradeComplementDetail do
  describe '.initialize' do
    subject(:line) { described_class.new(input) }

    let(:input) { File.read('spec/files/sequences_trades.txt').lines[18].chomp }

    it 'parses every field' do
      expect(line).to have_attributes(
        code: '35',
        record_type: 'MV',
        operation_number: '0001',
        account: '00900173030',
        currency: 'DKK',
        withholding_tax: BigDecimal('324'),
        commission: BigDecimal('60'),
        commission_tax: BigDecimal('12'),
        label: 'SHS NOVO NORDISK A/S DKK 0.1',
        nominal: BigDecimal('0.1'),
        nominal_currency: 'DKK',
      )
    end
  end
end
