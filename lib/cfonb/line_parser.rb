# frozen_string_literal: true

module CFONB
  module LineParser
    using CFONB::Refinements::Strings

    @parsers = {}
    @detail_parsers = {}

    def self.register(code, klass)
      @parsers[code] = klass
    end

    def self.for(code)
      @parsers[code]
    end

    def self.register_detail(sequence_code, record_code, klass)
      @detail_parsers[[sequence_code, record_code]] = klass
    end

    def self.detail_for(sequence_code, record_code)
      @detail_parsers.fetch([sequence_code, record_code], SequenceDetail)
    end

    def self.parse(input)
      self.for(input.first(2)).new(input)
    end
  end
end
