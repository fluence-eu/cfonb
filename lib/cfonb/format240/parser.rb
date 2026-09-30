# frozen_string_literal: true

module CFONB
  module Format240
    class Parser
      def initialize(input)
        @input = input
      end

      def parse
        sequences = []
        current_sequence = nil
        header_line_number = nil

        lines.each.with_index(1) do |line, line_number|
          unless line.size == LINE_LENGTH
            raise InvalidLineLengthError.new(
              "Line #{line_number} is #{line.size} characters long, expected #{LINE_LENGTH}",
            )
          end

          case line[0, 2]
          when HEADER_CODE
            if current_sequence
              raise UnfinishedSequenceError.new(
                "Line #{line_number}: header record while the sequence started on line #{header_line_number} " \
                'is not closed',
              )
            end

            current_sequence = Sequence.new(line, line_number)
            header_line_number = line_number
          when TOTAL_CODE
            unless current_sequence
              raise UnstartedSequenceError.new("Line #{line_number}: total record outside a sequence")
            end

            current_sequence.close(line, line_number)
            sequences << current_sequence
            current_sequence = nil
          else
            unless current_sequence
              raise UnstartedSequenceError.new("Line #{line_number}: record '#{line[0, 2]}' outside a sequence")
            end

            current_sequence.add_detail(line, line_number)
          end
        end

        if current_sequence
          raise UnfinishedSequenceError.new(
            "Line #{lines.size}: end of file while the sequence started on line #{header_line_number} is not closed",
          )
        end

        sequences
      end

      private

      attr_reader :input

      def lines
        @lines ||= input.each_line.map(&:chomp).tap { _1.pop if _1.last == '' }
      end
    end
  end
end
