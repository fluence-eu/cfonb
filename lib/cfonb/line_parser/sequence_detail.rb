# frozen_string_literal: true

module CFONB
  module LineParser
    class SequenceDetail < SequenceRecord
      BLANK_TO_NIL = proc { |value| value.empty? ? nil : value }
      DECIMAL = proc { |value, instance| instance.send(:parse_decimal, value) }
      ISO_DATE = proc { |value, instance| instance.send(:parse_iso_date, value) }

      DICTIONARY = [].freeze

      private

      def parse_decimal(input)
        return if input.empty?
        raise ParserError.new("Invalid decimal '#{input}'") unless input.match?(/\A-?\d+(\.\d+)?\z/)

        BigDecimal(input)
      end

      def parse_iso_date(input)
        return if input.empty?

        Date.strptime(input, '%Y%m%d')
      rescue Date::Error
        raise ParserError.new("Invalid date '#{input}'")
      end
    end
  end
end
