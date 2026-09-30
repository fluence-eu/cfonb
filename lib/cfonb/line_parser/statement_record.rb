# frozen_string_literal: true

module CFONB
  module LineParser
    class StatementRecord < Base
      BASE_DICTIONARY = [
        ['code', (0..1)].freeze,
        ['bank', (2..6)],
        ['branch', (11..15)],
        ['currency', (16..18)],
        ['scale', 19, proc { _1.to_i }], # rubocop:disable Style/SymbolProc
        ['account', (21..31)],
        ['date', (34..39), proc { |value, instance| instance.send(:parse_date, value) }],
      ].freeze

      attr_reader(*BASE_DICTIONARY.map(&:first))
    end
  end
end
