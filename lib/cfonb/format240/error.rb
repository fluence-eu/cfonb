# frozen_string_literal: true

module CFONB
  module Format240
    class InvalidLineLengthError < ParserError; end

    class UnstartedSequenceError < ParserError; end

    class UnfinishedSequenceError < ParserError; end

    class InvalidSequenceNumberError < ParserError; end

    class MismatchedTotalError < ParserError; end

    class InvalidDateError < ParserError; end

    class InvalidAmountError < ParserError; end
  end
end
