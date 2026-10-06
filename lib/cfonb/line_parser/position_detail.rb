# frozen_string_literal: true

module CFONB
  module LineParser
    class PositionDetail < SequenceDetail
      CASH_SECTION = '12'

      DICTIONARY = [
        ['account', (8..18)],
        ['section', (19..20)],
        ['line_currency', (21..23)],
        ['security_category', (24..26), BLANK_TO_NIL],
        ['security_code', (27..38), BLANK_TO_NIL],
        ['cash_currency', (39..41), BLANK_TO_NIL],
        ['label', (51..82), BLANK_TO_NIL],
        ['quotation_currency', (83..85)],
        ['nature', 86],
        ['quantity', (87..106), DECIMAL],
        ['valuation', (107..126), DECIMAL],
        ['price_in_account_currency', (128..147), DECIMAL],
        ['price', (148..167), DECIMAL],
        ['price_date', (168..175), ISO_DATE],
        ['nominal', (176..195), DECIMAL],
        ['exchange_rate', (196..215), DECIMAL],
        ['security_currency', (220..222), BLANK_TO_NIL],
      ].freeze

      attr_reader(*DICTIONARY.map(&:first))

      def cash?
        section == CASH_SECTION
      end

      def isin
        cash? ? nil : security_code
      end

      def percentage?
        !cash? && nature == '2'
      end

      CFONB::LineParser.register_detail('RQ', '34', self)
      CFONB::LineParser.register_detail('RM', '34', self)
    end
  end
end
