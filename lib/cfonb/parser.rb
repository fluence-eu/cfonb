# frozen_string_literal: true

module CFONB
  class Parser
    include RecordReader
    using CFONB::Refinements::Strings

    LINE_LENGTH = 120

    CODES = [
      PREVIOUS_BALANCE_CODE = '01',
      OPERATION_CODE = '04',
      OPERATION_DETAIL_CODE = '05',
      NEW_BALANCE_CODE = '07',
    ].freeze

    def parse(optimistic: false)
      @statements = []
      @current_statement = nil
      @current_operation = nil
      @optimistic = optimistic

      each_line { parse_line(_1) }

      statements
    end

    def parse_operation(optimistic: false)
      @current_operation = nil
      @optimistic = optimistic

      each_line { parse_operation_line(_1) }

      current_operation
    end

    private

    attr_reader :statements, :current_statement, :current_operation

    def split_records(line)
      Array.new(line.size / LINE_LENGTH) { line[_1 * LINE_LENGTH, LINE_LENGTH] }
    end

    def parse_line(line)
      return if line.strip.empty?
      raise InvalidCodeError.new("Invalid line code '#{line.first(2)}'") unless CODES.include?(line.first(2))

      line = CFONB::LineParser.parse(line)

      case line.code
      when PREVIOUS_BALANCE_CODE
        return handle_error(UnfinishedStatementError) if current_statement

        @current_statement = CFONB::Statement.new(line)
      when OPERATION_CODE
        return handle_error(UnstartedStatementError) unless current_statement

        current_statement.operations << current_operation if current_operation
        @current_operation = CFONB::Operation.new(line)
      when OPERATION_DETAIL_CODE
        return handle_error(UnstartedOperationError) unless current_operation

        current_operation.merge_detail(line)
      when NEW_BALANCE_CODE
        return handle_error(UnstartedStatementError) unless current_statement

        current_statement.operations << current_operation if current_operation
        current_statement.merge_new_balance(line)
        statements << current_statement

        @current_statement = nil
        @current_operation = nil
      end
    rescue CFONB::ParserError => e
      handle_error(e)
    end

    def parse_operation_line(line)
      line = CFONB::LineParser.parse(line)

      case line.code
      when OPERATION_CODE
        return handle_error(AlreadyDefinedOperationError) if current_operation

        @current_operation = CFONB::Operation.new(line)
      when OPERATION_DETAIL_CODE
        return handle_error(UnstartedOperationError) unless current_operation

        current_operation.merge_detail(line)
      else
        handle_error(UnhandledLineCodeError)
      end
    end
  end
end
