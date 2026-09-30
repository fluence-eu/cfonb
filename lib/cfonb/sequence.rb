# frozen_string_literal: true

module CFONB
  class Sequence
    include BankAccount

    attr_accessor(
      *%i[
        header_line total_line details
        operation_code previous_file_date
        currency_indicator decimals currency
        bank branch account holder_name
        created_on total_amount
      ],
    )

    def initialize(line)
      self.header_line = line.body
      self.operation_code = line.operation_code
      self.previous_file_date = line.previous_file_date
      self.currency_indicator = line.currency_indicator
      self.decimals = line.scale
      self.currency = line.currency
      self.bank = line.bank
      self.branch = line.branch
      self.account = line.account
      self.holder_name = line.holder_name
      self.details = []
    end

    def merge_total(line)
      self.total_line = line.body
      self.created_on = line.date
      self.total_amount = line.amount
    end

    def raw
      [
        header_line,
        *details.map(&:body),
        total_line,
      ].join("\n")
    end
  end
end
