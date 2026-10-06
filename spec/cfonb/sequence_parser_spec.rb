# frozen_string_literal: true

require 'cfonb'

describe CFONB::SequenceParser do
  describe '#parse' do
    subject(:sequences) { described_class.new(input).parse }

    let(:input) { File.read('spec/files/sequences.txt') }
    let(:lines) { input.lines.map(&:chomp) }

    context 'with a valid input' do
      it 'parses every sequence' do
        expect(sequences).to contain_exactly(
          an_instance_of(CFONB::Sequence),
          an_instance_of(CFONB::Sequence),
        )
      end

      it 'parses an empty sequence' do
        expect(sequences[0]).to have_attributes(
          operation_code: 'AB',
          previous_file_date: '280926',
          currency_indicator: 'E',
          decimals: nil,
          currency: nil,
          bank: '12345',
          branch: '00001',
          account: '00012345601',
          holder_name: 'ACME HOLDING',
          created_on: Date.new(2026, 9, 29),
          details: [],
          header_line: lines[0],
          total_line: lines[1],
        )
      end

      it 'parses a sequence with details' do
        expect(sequences[1]).to have_attributes(
          operation_code: 'CD',
          previous_file_date: '290926',
          currency_indicator: 'E',
          decimals: 2,
          currency: 'EUR',
          bank: '12345',
          branch: '00001',
          account: '00012345602',
          holder_name: 'ACME SERVICES',
          created_on: Date.new(2026, 9, 30),
          header_line: lines[2],
          total_line: lines[6],
        )
      end

      it 'keeps details raw whatever their code' do
        expect(sequences[1].details).to all(be_a(CFONB::LineParser::SequenceDetail))
        expect(sequences[1].details.map { [_1.code, _1.body] }).to eq(
          [
            ['34', lines[3]],
            ['35', lines[4]],
            ['34', lines[5]],
          ],
        )
      end
    end

    context 'with a position sequence' do
      let(:input) { File.read('spec/files/sequences_positions.txt') }

      it 'types its position records' do
        expect(sequences.flat_map(&:details)).to all(be_a(CFONB::LineParser::PositionDetail))
      end
    end

    context 'with trade sequences' do
      let(:input) { File.read('spec/files/sequences_trades.txt') }

      it 'types their operation and complement records' do
        expect(sequences[3].details.map(&:class)).to eq(
          [
            CFONB::LineParser::TradeDetail,
            CFONB::LineParser::TradeComplementDetail,
            CFONB::LineParser::TradeDetail,
            CFONB::LineParser::TradeComplementDetail,
          ],
        )
      end

      it 'keeps an empty sequence' do
        expect(sequences[0].details).to eq([])
      end
    end

    context 'with an IO' do
      subject(:sequences) { File.open('spec/files/sequences.txt') { described_class.new(_1).parse } }

      it 'parses every sequence' do
        expect(sequences.size).to eq(2)
      end
    end

    context 'with CRLF line endings' do
      let(:input) { File.read('spec/files/sequences.txt').gsub("\n", "\r\n") }

      it 'parses the same sequences' do
        expect(sequences.map(&:raw)).to eq(
          described_class.new(File.read('spec/files/sequences.txt')).parse.map(&:raw),
        )
      end
    end

    context 'without a trailing newline' do
      let(:input) { File.read('spec/files/sequences.txt').chomp }

      it 'parses every sequence' do
        expect(sequences.size).to eq(2)
      end
    end

    context 'with a trailing empty line' do
      let(:input) { "#{File.read('spec/files/sequences.txt')}\n" }

      it 'ignores it' do
        expect(sequences.size).to eq(2)
      end
    end

    context 'with a non UTF-8 encoded input' do
      let(:input) do
        File.read('spec/files/sequences.txt')
          .sub('ACME HOLDING ', 'SOCIÉTÉ ACME ')
          .encode(Encoding::ISO_8859_1)
      end

      it 'reads characters without transcoding' do
        expect(sequences[0].holder_name).to eq('SOCIÉTÉ ACME'.encode(Encoding::ISO_8859_1))
      end
    end

    context 'with an empty input' do
      let(:input) { '' }

      it 'returns no sequence' do
        expect(sequences).to eq([])
      end
    end

    {
      'sequences_invalid_line_length' => [
        CFONB::InvalidLineLengthError,
        'Line 2: 239 characters, expected 240',
      ],
      'sequences_detail_outside_sequence' => [
        CFONB::UnstartedSequenceError,
        "Line 1: record '34' outside a sequence",
      ],
      'sequences_total_outside_sequence' => [
        CFONB::UnstartedSequenceError,
        'Line 3: total record outside a sequence',
      ],
      'sequences_header_in_open_sequence' => [
        CFONB::UnfinishedSequenceError,
        'Line 2: header record while the sequence started on line 1 is not closed',
      ],
      'sequences_unterminated_sequence' => [
        CFONB::UnfinishedSequenceError,
        'Line 3: sequence not closed at end of file',
      ],
      'sequences_invalid_sequence_number' => [
        CFONB::InvalidSequenceNumberError,
        "Line 3: sequence number '000004', expected '000003'",
      ],
      'sequences_mismatched_total' => [
        CFONB::MismatchedSequenceTotalError,
        'Line 2: total record differs from its header on bank, account',
      ],
      'sequences_invalid_date' => [
        CFONB::ParserError,
        "Line 2: Invalid date '310226' for line 310226",
      ],
      'sequences_invalid_record_count' => [
        CFONB::ParserError,
        "Line 2: Invalid record count '00000000000A'",
      ],
    }.each do |file, (error, message)|
      context "with #{file}.txt" do
        let(:input) { File.read("spec/files/#{file}.txt") }

        it "raises #{error.name.split('::').last}" do
          expect { sequences }.to raise_error(error, message)
        end
      end
    end

    context 'with a header numbered after 000001' do
      let(:input) { File.read('spec/files/sequences.txt').sub('31000001AB', '31000002AB') }

      it 'raises InvalidSequenceNumberError' do
        expect { sequences }.to raise_error(
          CFONB::InvalidSequenceNumberError,
          "Line 1: sequence number '000002', expected '000001'",
        )
      end
    end

    context 'with a total whose operation code and branch differ from its header' do
      let(:input) do
        File.read('spec/files/sequences.txt').sub('39000002AB290926E    1234500001', '39000002ZZ290926E    1234599999')
      end

      it 'raises MismatchedSequenceTotalError' do
        expect { sequences }.to raise_error(
          CFONB::MismatchedSequenceTotalError,
          'Line 2: total record differs from its header on operation_code, branch',
        )
      end
    end

    context 'with a total whose record count differs from its details' do
      let(:input) { File.read('spec/files/sequences.txt').sub('000000000003', '000000000002') }

      it 'raises MismatchedSequenceTotalError' do
        expect { sequences }.to raise_error(
          CFONB::MismatchedSequenceTotalError,
          'Line 7: total record counts 2 detail records, 3 found',
        )
      end
    end

    context 'when optimistic' do
      subject(:sequences) { described_class.new(input).parse(optimistic: true) }

      context 'with a detail outside a sequence' do
        let(:input) { File.read('spec/files/sequences_detail_outside_sequence.txt') }

        it 'skips the detail' do
          expect(sequences.map(&:account)).to eq(['00012345601'])
        end
      end

      context 'with an unterminated sequence' do
        let(:input) { File.read('spec/files/sequences_unterminated_sequence.txt') }

        it 'drops the unterminated sequence' do
          expect(sequences.map(&:account)).to eq(['00012345601'])
        end
      end

      context 'with an invalid line length' do
        let(:input) { File.read('spec/files/sequences_invalid_line_length.txt') }

        it 'skips the line' do
          expect(sequences).to eq([])
        end
      end
    end
  end

  describe 'CFONB.parse_sequences' do
    it 'parses the sequences' do
      expect(CFONB.parse_sequences(File.read('spec/files/sequences.txt')).map(&:account)).to eq(
        %w[00012345601 00012345602],
      )
    end

    it 'forwards optimistic' do
      input = File.read('spec/files/sequences_detail_outside_sequence.txt')

      expect(CFONB.parse_sequences(input, optimistic: true).size).to eq(1)
    end
  end
end
