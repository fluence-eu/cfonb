# frozen_string_literal: true

module CFONB
  module Format240
    LINE_LENGTH = 240
    HEADER_CODE = '31'
    TOTAL_CODE = '39'

    def self.parse(input)
      Parser.new(input).parse
    end
  end
end
