# frozen_string_literal: true

module CFONB
  module Format240
    class Sequence
      include BankAccount
      using CFONB::Refinements::Strings

      IDENTITY_FIELDS = {
        'operation_code' => (8..9),
        'bank' => (21..25),
        'branch' => (26..30),
        'account' => (31..41),
      }.freeze

      attr_reader(
        *%i[
          header_line total_line details
          operation_code previous_file_date
          currency_indicator decimals currency
          bank branch account holder_name
          created_on total_amount
        ],
      )

      def initialize(line, line_number)
        check_sequence_number(line, line_number)

        @header_line = line
        @details = []
        @operation_code = line[8..9]
        @previous_file_date = line[10..15]
        @currency_indicator = line[16]
        @decimals = line[17].presence&.to_i
        @currency = line[18..20].presence
        @bank = line[21..25].strip
        @branch = line[26..30].strip
        @account = line[31..41].strip
        @holder_name = line[42..65].strip
      end

      def add_detail(line, line_number)
        check_sequence_number(line, line_number)

        details << Detail.new(code: line[0..1], line: line)
      end

      def close(line, line_number)
        check_sequence_number(line, line_number)
        check_identity(line, line_number)

        @total_line = line
        @created_on = parse_date(line[10..15], line_number)
        @total_amount = parse_amount(line[228..239], line_number)
      end

      def raw
        [
          header_line,
          *details.map(&:line),
          total_line,
        ].join("\n")
      end

      private

      def check_sequence_number(line, line_number)
        expected = '%06d' % (header_line ? details.size + 2 : 1)
        return if line[2..7] == expected

        raise InvalidSequenceNumberError.new(
          "Line #{line_number}: sequential number '#{line[2..7]}', expected '#{expected}'",
        )
      end

      def check_identity(line, line_number)
        mismatches = IDENTITY_FIELDS.reject { |_field, range| header_line[range] == line[range] }.keys
        return if mismatches.empty?

        raise MismatchedTotalError.new(
          "Line #{line_number}: total record differs from its header on #{mismatches.join(', ')}",
        )
      end

      def parse_date(input, line_number)
        raise Date::Error unless input.match?(/\A\d{6}\z/)

        Date.strptime(input, '%d%m%y')
      rescue Date::Error
        raise InvalidDateError.new("Line #{line_number}: invalid date '#{input}'")
      end

      def parse_amount(input, line_number)
        return if input.strip.empty?
        return input.to_i if input.match?(/\A\d{12}\z/)

        raise InvalidAmountError.new("Line #{line_number}: invalid total amount '#{input}'")
      end
    end
  end
end
