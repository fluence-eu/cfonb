# frozen_string_literal: true

module CFONB
  module BankAccount
    def rib
      # https://fr.wikipedia.org/wiki/Clé_RIB
      key = 97 - ((
        (bank.to_i * 89) +
        (branch.to_i * 15) +
        (account.upcase.tr('A-IJ-RS-Z', '1-91-92-9').to_i * 3)
      ) % 97)

      "#{bank}#{branch}#{account}#{key.to_s.rjust(2, '0')}"
    end

    def iban
      # https://fr.wikipedia.org/wiki/International_Bank_Account_Number
      normalized_rib = "#{rib}FR00".upcase.gsub(/[A-Z]/) { _1.ord - 55 }
      key = 98 - (normalized_rib.to_i % 97)

      "FR#{key.to_s.rjust(2, '0')}#{rib}"
    end
  end
end
