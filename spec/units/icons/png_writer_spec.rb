# frozen_string_literal: true

RSpec.describe Raintron::PngWriter do
  describe '.encode' do
    it 'produces bytes with the PNG signature' do
      rgba = [0, 0, 0, 255].pack('C4') * 4 # 2x2 solid black
      png = described_class.encode(width: 2, height: 2, rgba:)

      expect(png.byteslice(0, 8)).to eq("\x89PNG\r\n\x1a\n".b)
    end

    it 'round-trips through PngDecoder with identical pixels' do
      pixels = [
        [255, 0, 0, 255], [0, 255, 0, 255],
        [0, 0, 255, 255], [255, 255, 0, 128]
      ]
      rgba = pixels.map { |p| p.pack('C4') }.join
      png = described_class.encode(width: 2, height: 2, rgba:)

      decoded = Raintron::PngDecoder.decode(png)

      expect(decoded[:width]).to eq(2)
      expect(decoded[:height]).to eq(2)
      expect(decoded[:rgba]).to eq(rgba)
    end
  end
end
