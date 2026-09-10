# frozen_string_literal: true

RSpec.describe Raintron::IcnsWriter do
  describe '.encode' do
    def png_for(size)
      Raintron::PngWriter.encode(width: size, height: size, rgba: [0, 0, 0, 255].pack('C4') * (size * size))
    end

    let(:pngs_by_size) { described_class::SIZE_MAP.map { |_, size| size }.uniq.to_h { |size| [size, png_for(size)] } }

    it 'starts with the "icns" magic and a big-endian total length' do
      icns = described_class.encode(pngs_by_size:)

      expect(icns.byteslice(0, 4)).to eq('icns'.b)
      expect(icns.byteslice(4, 4).unpack1('N')).to eq(icns.bytesize)
    end

    it 'includes every entry from SIZE_MAP, each holding the right PNG bytes' do
      icns = described_class.encode(pngs_by_size:)
      offset = 8

      described_class::SIZE_MAP.each do |type, size|
        expect(icns.byteslice(offset, 4)).to eq(type.b)
        length = icns.byteslice(offset + 4, 4).unpack1('N')
        png = pngs_by_size.fetch(size)

        expect(length).to eq(8 + png.bytesize)
        expect(icns.byteslice(offset + 8, png.bytesize)).to eq(png)

        offset += length
      end

      expect(offset).to eq(icns.bytesize)
    end

    it 'includes the icp4/icp5 @1x slots (omitting them breaks small-icon rendering, see comments)' do
      expect(described_class::SIZE_MAP.map(&:first)).to include('icp4', 'icp5')
    end

    it 'raises KeyError if a required size is missing from pngs_by_size' do
      incomplete = pngs_by_size.reject { |size, _| size == 16 }
      expect { described_class.encode(pngs_by_size: incomplete) }.to raise_error(KeyError)
    end
  end
end
