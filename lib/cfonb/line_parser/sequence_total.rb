# frozen_string_literal: true

module CFONB
  module LineParser
    class SequenceTotal < SequenceRecord
      DICTIONARY = [
        *ENVELOPE_DICTIONARY,
        ['date', (10..15), proc { |value, instance| instance.send(:parse_date, value) }],
        ['amount', (228..239), proc { |value, instance| instance.send(:parse_cents, value) }],
      ].freeze

      attr_reader(*DICTIONARY.map(&:first))

      CFONB::LineParser.register(CFONB::SequenceParser::SEQUENCE_TOTAL_CODE, self)

      private

      def parse_cents(input)
        return if input.empty?
        raise ParserError.new("Invalid amount '#{input}'") unless input.match?(/\A\d{12}\z/)

        input.to_i
      end
    end
  end
end
