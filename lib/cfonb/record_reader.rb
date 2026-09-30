# frozen_string_literal: true

module CFONB
  module RecordReader
    def initialize(input)
      @input = input
    end

    private

    attr_reader :input, :optimistic

    def each_line
      input.each_line.with_index(1) do |line, line_number|
        split_records(line).each { yield _1, line_number }
      end
    end

    def handle_error(error)
      raise error unless optimistic
    end
  end
end
