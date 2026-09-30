# frozen_string_literal: true

require 'cfonb'

describe CFONB::Format240::Parser do
  describe '#parse' do
    subject(:sequences) { described_class.new(input).parse }

    let(:input) { File.read('spec/files/format240_example.txt') }
    let(:lines) { input.lines.map(&:chomp) }

    context 'with a valid input' do
      it 'parses every sequence' do
        expect(sequences).to contain_exactly(
          an_instance_of(CFONB::Format240::Sequence),
          an_instance_of(CFONB::Format240::Sequence),
        )
      end

      it 'decodes an empty sequence' do
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
          total_amount: nil,
          details: [],
          header_line: lines[0],
          total_line: lines[1],
          raw: lines[0..1].join("\n"),
          rib: '12345000010001234560127',
          iban: 'FR7612345000010001234560127',
        )
      end

      it 'decodes a sequence with details' do
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
          total_amount: 123_456,
          header_line: lines[2],
          total_line: lines[6],
          raw: lines[2..6].join("\n"),
          rib: '12345000010001234560224',
          iban: 'FR7612345000010001234560224',
        )
      end

      it 'keeps details raw whatever their code' do
        expect(sequences[1].details).to eq(
          [
            CFONB::Format240::Detail.new(code: '34', line: lines[3]),
            CFONB::Format240::Detail.new(code: '35', line: lines[4]),
            CFONB::Format240::Detail.new(code: '34', line: lines[5]),
          ],
        )
      end
    end

    context 'with CRLF line endings' do
      let(:input) { File.read('spec/files/format240_example.txt').gsub("\n", "\r\n") }

      it 'parses the same sequences' do
        expect(sequences.map(&:raw)).to eq(
          described_class.new(File.read('spec/files/format240_example.txt')).parse.map(&:raw),
        )
      end
    end

    context 'without a trailing newline' do
      let(:input) { File.read('spec/files/format240_example.txt').chomp }

      it 'parses every sequence' do
        expect(sequences.size).to eq(2)
      end
    end

    context 'with a trailing empty line' do
      let(:input) { "#{File.read('spec/files/format240_example.txt')}\n" }

      it 'ignores it' do
        expect(sequences.size).to eq(2)
      end
    end

    context 'with a non UTF-8 encoded input' do
      let(:input) do
        File.read('spec/files/format240_example.txt')
          .sub('ACME HOLDING ', 'SOCIÉTÉ ACME ')
          .encode(Encoding::ISO_8859_1)
      end

      it 'decodes characters without transcoding' do
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
      'format240_invalid_line_length' => [
        CFONB::Format240::InvalidLineLengthError,
        'Line 2 is 239 characters long, expected 240',
      ],
      'format240_detail_outside_sequence' => [
        CFONB::Format240::UnstartedSequenceError,
        "Line 1: record '34' outside a sequence",
      ],
      'format240_total_outside_sequence' => [
        CFONB::Format240::UnstartedSequenceError,
        'Line 3: total record outside a sequence',
      ],
      'format240_header_in_open_sequence' => [
        CFONB::Format240::UnfinishedSequenceError,
        'Line 2: header record while the sequence started on line 1 is not closed',
      ],
      'format240_unterminated_sequence' => [
        CFONB::Format240::UnfinishedSequenceError,
        'Line 6: end of file while the sequence started on line 3 is not closed',
      ],
      'format240_invalid_sequence_number' => [
        CFONB::Format240::InvalidSequenceNumberError,
        "Line 3: sequential number '000004', expected '000003'",
      ],
      'format240_mismatched_total' => [
        CFONB::Format240::MismatchedTotalError,
        'Line 2: total record differs from its header on bank, account',
      ],
      'format240_invalid_date' => [
        CFONB::Format240::InvalidDateError,
        "Line 2: invalid date '310226'",
      ],
      'format240_invalid_amount' => [
        CFONB::Format240::InvalidAmountError,
        "Line 2: invalid total amount '00000012345A'",
      ],
    }.each do |file, (error, message)|
      context "with #{file}.txt" do
        let(:input) { File.read("spec/files/#{file}.txt") }

        it "raises #{error.name.split('::').last}" do
          expect { sequences }.to raise_error(error, message)
        end

        it 'raises a parser error' do
          expect { sequences }.to raise_error(CFONB::ParserError)
        end
      end
    end

    context 'with a header numbered after 000001' do
      let(:input) { File.read('spec/files/format240_example.txt').sub('31000001AB', '31000002AB') }

      it 'raises InvalidSequenceNumberError' do
        expect { sequences }.to raise_error(
          CFONB::Format240::InvalidSequenceNumberError,
          "Line 1: sequential number '000002', expected '000001'",
        )
      end
    end

    context 'with a total whose operation code and branch differ from its header' do
      let(:input) do
        File.read('spec/files/format240_example.txt').sub('39000002AB290926E    1234500001', '39000002ZZ290926E    1234599999')
      end

      it 'raises MismatchedTotalError' do
        expect { sequences }.to raise_error(
          CFONB::Format240::MismatchedTotalError,
          'Line 2: total record differs from its header on operation_code, branch',
        )
      end
    end

    context 'with a blank total date' do
      let(:input) { File.read('spec/files/format240_example.txt').sub('39000002AB290926', '39000002AB      ') }

      it 'raises InvalidDateError' do
        expect { sequences }.to raise_error(CFONB::Format240::InvalidDateError, "Line 2: invalid date '      '")
      end
    end
  end
end
