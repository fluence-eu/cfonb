# frozen_string_literal: true

module CFONB
  module LineParser
    class SequenceRecord < Base
      BASE_DICTIONARY = [
        ['code', (0..1)].freeze,
        ['sequence_number', (2..7)],
      ].freeze

      ENVELOPE_DICTIONARY = [
        ['operation_code', (8..9)],
        ['bank', (21..25)],
        ['branch', (26..30)],
        ['account', (31..41)],
        ['holder_name', (42..65)],
      ].freeze

      attr_reader(*BASE_DICTIONARY.map(&:first))
    end
  end
end
