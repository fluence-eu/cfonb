# frozen_string_literal: true

module CFONB
  module LineParser
    class TradeDetail < SequenceDetail
      DICTIONARY = [
        ['record_type', (8..9)],
        ['operation_number', (10..13)],
        ['account', (14..24)],
        ['transaction_code', (26..29)],
        ['operation_date', (30..37), ISO_DATE],
        ['value_date', (46..53), ISO_DATE],
        ['isin', (54..65), BLANK_TO_NIL],
        ['quotation_place', (66..68), BLANK_TO_NIL],
        ['nature', 69],
        ['quantity', (70..89), DECIMAL],
        ['currency', (90..92)],
        ['price', (94..113), DECIMAL],
        ['gross_amount', (114..133), DECIMAL],
        ['market_fees', (154..173), DECIMAL],
        ['settlement_currency', (174..176)],
        ['net_amount', (177..196), DECIMAL],
        ['exchange_rate', (218..239), DECIMAL],
      ].freeze

      attr_reader(*DICTIONARY.map(&:first))

      CFONB::LineParser.register_detail('AO', '34', self)
    end
  end
end
