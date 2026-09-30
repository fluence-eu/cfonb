# frozen_string_literal: true

module CFONB
  module LineParser
    class TradeComplementDetail < SequenceDetail
      DICTIONARY = [
        ['record_type', (8..9)],
        ['operation_number', (10..13)],
        ['account', (14..24)],
        ['currency', (25..27)],
        ['withholding_tax', (28..47), DECIMAL],
        ['commission', (48..67), DECIMAL],
        ['commission_tax', (68..87), DECIMAL],
        ['label', (128..159), BLANK_TO_NIL],
        ['nominal', (163..182), DECIMAL],
        ['nominal_currency', (183..185), BLANK_TO_NIL],
      ].freeze

      attr_reader(*DICTIONARY.map(&:first))

      CFONB::LineParser.register_detail('AO', '35', self)
    end
  end
end
