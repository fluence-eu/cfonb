# frozen_string_literal: true

require 'cfonb'

describe CFONB::LineParser::PositionDetail do
  describe '.initialize' do
    subject(:line) { described_class.new(input) }

    let(:lines) { File.read('spec/files/sequences_positions.txt').lines.map(&:chomp) }

    context 'with a security quoted per unit' do
      let(:input) { lines[3] }

      it 'parses every field' do
        expect(line).to have_attributes(
          code: '34',
          sequence_number: '000004',
          account: '00900119030',
          section: '02',
          line_currency: 'USD',
          quotation_place: '067',
          security_code: 'US5949181045',
          cash_currency: nil,
          label: 'REG SHS MICROSOFT CORP USD 0.000',
          quotation_currency: 'USD',
          nature: '1',
          quantity: BigDecimal('50'),
          valuation: BigDecimal('21250'),
          price_in_account_currency: BigDecimal('425'),
          price: BigDecimal('500'),
          price_date: Date.new(2026, 9, 29),
          nominal: BigDecimal('0'),
          exchange_rate: BigDecimal('0.85'),
          security_currency: 'USD',
          isin: 'US5949181045',
          cash?: false,
          percentage?: false,
        )
      end
    end

    context 'with a security quoted as a percentage of its nominal' do
      let(:input) { lines[4] }

      it 'flags the percentage quotation' do
        expect(line).to have_attributes(
          section: '08',
          nature: '2',
          quantity: BigDecimal('100000'),
          price: BigDecimal('95.5'),
          valuation: BigDecimal('95500'),
          percentage?: true,
        )
      end
    end

    context 'with a negative cash balance' do
      let(:input) { lines[1] }

      it 'parses the signed quantity and valuation, without ISIN' do
        expect(line).to have_attributes(
          section: '12',
          security_code: '250',
          cash_currency: 'EUR',
          label: nil,
          quantity: BigDecimal('-1250.4'),
          valuation: BigDecimal('-1250.4'),
          isin: nil,
          cash?: true,
          percentage?: false,
        )
      end
    end

    context 'with a foreign currency cash balance' do
      let(:input) { lines[5] }

      it 'carries the exchange rate as its price in account currency' do
        expect(line).to have_attributes(
          cash_currency: 'USD',
          quantity: BigDecimal('1000'),
          price_in_account_currency: BigDecimal('0.85'),
          valuation: BigDecimal('850'),
        )
      end
    end

    context 'with an invalid decimal' do
      let(:input) { lines[2].dup.tap { |line| line[87, 20] = '0000000000020O.00000' } }

      it 'raises a parser error' do
        expect { line }.to raise_error(CFONB::ParserError, "Invalid decimal '0000000000020O.00000'")
      end
    end
  end
end
