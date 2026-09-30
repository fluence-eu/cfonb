# frozen_string_literal: true

require 'cfonb'

describe CFONB::LineParser::TradeDetail do
  describe '.initialize' do
    subject(:line) { described_class.new(input) }

    let(:lines) { File.read('spec/files/sequences_trades.txt').lines.map(&:chomp) }

    context 'with a purchase' do
      let(:input) { lines[13] }

      it 'parses every field' do
        expect(line).to have_attributes(
          code: '34',
          record_type: 'MV',
          operation_number: '0002',
          account: '00900119030',
          transaction_code: 'PURC',
          booking_date: Date.new(2026, 9, 22),
          value_date: Date.new(2026, 9, 24),
          isin: 'DE0005557508',
          security_category: '025',
          nature: '1',
          quantity: BigDecimal('100'),
          currency: 'EUR',
          price: BigDecimal('25'),
          gross_amount: BigDecimal('2500'),
          market_fees: BigDecimal('0.5'),
          settlement_currency: 'EUR',
          net_amount: BigDecimal('2510.1'),
          exchange_rate: BigDecimal('1'),
        )
      end
    end

    context 'with a dividend settled in another currency' do
      let(:input) { lines[17] }

      it 'parses the settlement currency and the exchange rate' do
        expect(line).to have_attributes(
          transaction_code: 'DIVI',
          currency: 'DKK',
          gross_amount: BigDecimal('1200'),
          settlement_currency: 'EUR',
          net_amount: BigDecimal('107.2'),
          exchange_rate: BigDecimal('7.5'),
        )
      end
    end
  end
end
