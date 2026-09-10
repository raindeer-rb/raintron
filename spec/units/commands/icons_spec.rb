# frozen_string_literal: true

require 'tmpdir'
require_relative '../../../lib/commands/icons'

RSpec.describe Raintron::Commands::Icons do
  around do |example|
    Dir.mktmpdir { |dir| Dir.chdir(dir) { example.run } }
  end

  describe '#run' do
    it 'uses a positional name over the directory basename' do
      described_class.run(argv: ['custom'])
      expect(File).to exist('icons/custom.icns')
    end

    it 'falls back to the directory basename when no name is given' do
      described_class.run(argv: [])
      expect(File).to exist("icons/#{File.basename(Dir.pwd)}.icns")
    end

    it 'passes --source through to IconGenerator' do
      source = File.join(Dir.pwd, 'logo.png')
      File.binwrite(source, Raintron::PngWriter.encode(width: 4, height: 4, rgba: [9, 9, 9, 255].pack('C4') * 16))

      expect(Raintron::IconGenerator).to receive(:generate)
        .with(hash_including(source:)).and_call_original

      described_class.run(argv: ['custom', '--source', source])
    end
  end
end
