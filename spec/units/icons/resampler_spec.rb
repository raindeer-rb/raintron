# frozen_string_literal: true

RSpec.describe Raintron::Resampler do
  describe '.resize' do
    it 'returns the input unchanged when src and dst sizes match' do
      rgba = [1, 2, 3, 4].pack('C4') * 4
      expect(described_class.resize(rgba:, src_w: 2, src_h: 2, dst_w: 2, dst_h: 2)).to equal(rgba)
    end

    it 'averages a 2x2 block down to a single pixel' do
      pixels = [[0, 0, 0, 0], [100, 0, 0, 0], [0, 100, 0, 0], [0, 0, 100, 0]]
      rgba = pixels.map { |p| p.pack('C4') }.join

      result = described_class.resize(rgba:, src_w: 2, src_h: 2, dst_w: 1, dst_h: 1)

      expect(result.unpack('C4')).to eq([25, 25, 25, 0])
    end

    it 'produces the expected byte count for a downscale' do
      rgba = [0, 0, 0, 255].pack('C4') * (4 * 4)
      result = described_class.resize(rgba:, src_w: 4, src_h: 4, dst_w: 2, dst_h: 2)
      expect(result.bytesize).to eq(2 * 2 * 4)
    end
  end
end
