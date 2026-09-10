# frozen_string_literal: true

RSpec.describe Raintron::IcoWriter do
  describe '.encode' do
    let(:png) { Raintron::PngWriter.encode(width: 16, height: 16, rgba: [0, 0, 0, 255].pack('C4') * (16 * 16)) }

    it 'writes a well-formed ICONDIR header (reserved=0, type=1, count=N)' do
      ico = described_class.encode(entries: [{ size: 16, png: }])
      reserved, type, count = ico.byteslice(0, 6).unpack('v3')

      expect([reserved, type, count]).to eq([0, 1, 1])
    end

    it 'places the correct data offset and size in each directory entry' do
      ico = described_class.encode(entries: [{ size: 16, png: }])
      entry = ico.byteslice(6, 16)
      _w, _h, _colors, _reserved, _planes, _bpp, data_size, offset = entry.unpack('C4v2V2')

      expect(data_size).to eq(png.bytesize)
      expect(ico.byteslice(offset, data_size)).to eq(png)
    end

    it 'encodes width/height as 0 for a 256px entry (per the ICO spec)' do
      big_png = Raintron::PngWriter.encode(width: 256, height: 256, rgba: [0, 0, 0, 255].pack('C4') * (256 * 256))
      ico = described_class.encode(entries: [{ size: 256, png: big_png }])
      width, height = ico.byteslice(6, 2).unpack('C2')

      expect([width, height]).to eq([0, 0])
    end
  end
end
