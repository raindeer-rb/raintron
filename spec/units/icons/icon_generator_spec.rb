# frozen_string_literal: true

require 'tmpdir'

RSpec.describe Raintron::IconGenerator do
  describe '.generate' do
    it 'writes an icns, ico, and png with no source (procedural placeholder)' do
      Dir.mktmpdir do |dir|
        paths = described_class.generate(output_dir: dir, basename: 'app')

        expect(File.read(paths[:icns], 4)).to eq('icns')
        expect(File.read(paths[:ico], 4)).to include("\x00\x00\x01\x00".b)
        expect(File.binread(paths[:png], 8)).to eq("\x89PNG\r\n\x1a\n".b)
      end
    end

    it 'decodes and resamples a supplied source image instead of rendering a placeholder' do
      Dir.mktmpdir do |dir|
        source = File.join(dir, 'source.png')
        source_rgba = [200, 100, 50, 255].pack('C4') * (32 * 32)
        File.binwrite(source, Raintron::PngWriter.encode(width: 32, height: 32, rgba: source_rgba))

        paths = described_class.generate(output_dir: dir, basename: 'app', source:)
        decoded = Raintron::PngDecoder.decode(File.binread(paths[:png]))

        # A solid-color source resamples to the same solid color at every size.
        expect(decoded[:rgba].unpack('C4')).to eq([200, 100, 50, 255])
      end
    end

    it 'only decodes the source once even though multiple sizes are generated' do
      Dir.mktmpdir do |dir|
        source = File.join(dir, 'source.png')
        File.binwrite(source, Raintron::PngWriter.encode(width: 8, height: 8, rgba: [1, 2, 3, 4].pack('C4') * 64))

        expect(Raintron::PngDecoder).to receive(:decode).once.and_call_original
        described_class.generate(output_dir: dir, basename: 'app', source:)
      end
    end
  end
end
