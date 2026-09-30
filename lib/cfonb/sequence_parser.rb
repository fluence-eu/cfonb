# frozen_string_literal: true

module CFONB
  class SequenceParser
    include RecordReader
    using CFONB::Refinements::Strings

    LINE_LENGTH = 240

    SEQUENCE_HEADER_CODE = '31'
    SEQUENCE_TOTAL_CODE = '39'

    IDENTITY_ATTRIBUTES = %w[operation_code bank branch account].freeze

    def parse(optimistic: false)
      @sequences = []
      @current_sequence = nil
      @optimistic = optimistic

      each_line { parse_line(_1, _2) }

      if current_sequence
        handle_error(
          UnfinishedSequenceError.new("Line #{current_sequence_line_number}: sequence not closed at end of file"),
        )
      end

      sequences
    end

    private

    attr_reader :sequences, :current_sequence, :current_sequence_line_number

    def split_records(line)
      record = line.chomp
      record.empty? ? [] : [record]
    end

    def parse_line(line, line_number)
      raise InvalidLineLengthError.new("#{line.size} characters, expected #{LINE_LENGTH}") if line.size != LINE_LENGTH

      case line.first(2)
      when SEQUENCE_HEADER_CODE
        if current_sequence
          raise UnfinishedSequenceError.new(
            "header record while the sequence started on line #{current_sequence_line_number} is not closed",
          )
        end

        line = CFONB::LineParser.parse(line)
        check_sequence_number(line)

        @current_sequence = CFONB::Sequence.new(line)
        @current_sequence_line_number = line_number
      when SEQUENCE_TOTAL_CODE
        raise UnstartedSequenceError.new('total record outside a sequence') unless current_sequence

        line = CFONB::LineParser.parse(line)
        check_sequence_number(line)
        check_identity(line)

        current_sequence.merge_total(line)
        sequences << current_sequence

        @current_sequence = nil
      else
        raise UnstartedSequenceError.new("record '#{line.first(2)}' outside a sequence") unless current_sequence

        line = CFONB::LineParser::SequenceDetail.new(line)
        check_sequence_number(line)

        current_sequence.details << line
      end
    rescue CFONB::ParserError => e
      handle_error(e.class.new("Line #{line_number}: #{e.message}"))
    end

    def check_sequence_number(line)
      expected = '%06d' % (current_sequence ? current_sequence.details.size + 2 : 1)
      return if line.sequence_number == expected

      raise InvalidSequenceNumberError.new("sequence number '#{line.sequence_number}', expected '#{expected}'")
    end

    def check_identity(line)
      mismatches = IDENTITY_ATTRIBUTES.reject { current_sequence.public_send(_1) == line.public_send(_1) }
      return if mismatches.empty?

      raise MismatchedSequenceTotalError.new("total record differs from its header on #{mismatches.join(', ')}")
    end
  end
end
