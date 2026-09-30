# frozen_string_literal: true

module CFONB
  module LineParser
    class SequenceHeader < SequenceRecord
      DICTIONARY = [
        *ENVELOPE_DICTIONARY,
        ['previous_file_date', (10..15)],
        ['currency_indicator', 16],
        ['scale', 17, proc { _1.empty? ? nil : _1.to_i }],
        ['currency', (18..20), proc { _1.empty? ? nil : _1 }],
      ].freeze

      attr_reader(*DICTIONARY.map(&:first))

      CFONB::LineParser.register(CFONB::SequenceParser::SEQUENCE_HEADER_CODE, self)
    end
  end
end
