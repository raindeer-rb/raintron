# frozen_string_literal: true

require 'zlib'

RSpec.describe Raintron::PngDecoder do
  describe '.decode' do
    it 'raises UnsupportedSourceError for a non-PNG file' do
      expect { described_class.decode('not a png') }.to raise_error(Raintron::UnsupportedSourceError, /not a PNG/)
    end

    it 'raises a JPEG-specific UnsupportedSourceError for JPEG magic bytes' do
      jpeg_ish = "\xff\xd8\xffrest".b
      expect { described_class.decode(jpeg_ish) }.to raise_error(Raintron::UnsupportedSourceError, /JPEG/)
    end

    it 'decodes an RGB (color type 2) PNG and expands it to RGBA' do
      rgb = [10, 20, 30].pack('C3') * 4 # 2x2 solid color, 3 channels
      png = build_png(width: 2, height: 2, channels: 3, pixel_bytes: rgb)

      decoded = described_class.decode(png)

      expect(decoded[:rgba]).to eq([10, 20, 30, 255].pack('C4') * 4)
    end

    it 'raises UnsupportedSourceError for an unsupported bit depth' do
      png = build_png(width: 1, height: 1, channels: 4, pixel_bytes: [0, 0, 0, 255].pack('C4'), bit_depth: 16)
      expect { described_class.decode(png) }.to raise_error(Raintron::UnsupportedSourceError, /bit depth/)
    end
  end

  # Hand-builds a minimal, valid, filter-type-0 PNG with an arbitrary bit depth/color
  # type, bypassing PngWriter (which only ever emits 8-bit RGBA) so decode's own
  # validation logic is what's actually under test here, not PngWriter's output.
  def build_png(width:, height:, channels:, pixel_bytes:, bit_depth: 8)
    color_type = channels == 4 ? 6 : 2
    raw = build_raw_scanlines(width:, height:, channels:, pixel_bytes:)
    idat = Zlib::Deflate.deflate(raw)
    ihdr = [width, height, bit_depth, color_type, 0, 0, 0].pack('N2C5')

    "\x89PNG\r\n\x1a\n".b + png_chunk('IHDR', ihdr) + png_chunk('IDAT', idat) + png_chunk('IEND', ''.b)
  end

  def build_raw_scanlines(width:, height:, channels:, pixel_bytes:)
    row_bytes = width * channels
    height.times.map { |row| "\x00".b + pixel_bytes.byteslice(row * row_bytes, row_bytes) }.join
  end

  def png_chunk(type, data)
    type_and_data = type.b + data.b
    [data.bytesize].pack('N') + type_and_data + [Zlib.crc32(type_and_data)].pack('N')
  end
end
