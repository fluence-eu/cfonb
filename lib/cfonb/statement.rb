# frozen_string_literal: true

module CFONB
  class Statement
    include BankAccount

    attr_accessor(
      *%i[
        begin_raw end_raw
        bank branch currency account
        from from_balance
        to to_balance
        operations
      ],
    )

    def initialize(line)
      self.begin_raw = line.body
      self.bank = line.bank
      self.branch = line.branch
      self.currency = line.currency
      self.account = line.account
      self.from = line.date
      self.from_balance = line.amount
      self.operations = []
    end

    def merge_new_balance(line)
      self.end_raw = line.body
      self.to = line.date
      self.to_balance = line.amount
    end

    def raw
      [
        begin_raw,
        operations.map(&:raw),
        end_raw,
      ].join("\n")
    end
  end
end
