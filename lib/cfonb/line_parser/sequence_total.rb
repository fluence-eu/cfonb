# frozen_string_literal: true

module CFONB
  module LineParser
    class SequenceTotal < SequenceRecord
      DICTIONARY = [
        *ENVELOPE_DICTIONARY,
        ['date', (10..15), proc { |value, instance| instance.send(:parse_date, value) }],
        ['record_count', (128..139), proc { |value, instance| instance.send(:parse_record_count, value) }],
      ].freeze

      attr_reader(*DICTIONARY.map(&:first))

      CFONB::LineParser.register(CFONB::SequenceParser::SEQUENCE_TOTAL_CODE, self)

      private

      def parse_record_count(input)
        raise ParserError.new("Invalid record count '#{input}'") unless input.match?(/\A\d{12}\z/)

        input.to_i
      end
    end
  end
end
