# frozen_string_literal: true

RSpec.describe Raintron::Renderer do
  describe '.render' do
    it 'produces width*height*4 bytes' do
      rgba = described_class.render(size: 16)
      expect(rgba.bytesize).to eq(16 * 16 * 4)
    end

    it 'paints the center pixel with the foreground color for a circle' do
      background = [1, 2, 3, 255]
      foreground = [250, 251, 252, 255]
      rgba = described_class.render(size: 17, background:, foreground:, shape: :circle)

      center = 8
      index = ((center * 17) + center) * 4
      expect(rgba.byteslice(index, 4).unpack('C4')).to eq(foreground)
    end

    it 'paints a corner pixel with the background color for a circle' do
      background = [1, 2, 3, 255]
      foreground = [250, 251, 252, 255]
      rgba = described_class.render(size: 17, background:, foreground:, shape: :circle)

      expect(rgba.byteslice(0, 4).unpack('C4')).to eq(background)
    end

    it 'raises for an unknown shape' do
      expect { described_class.render(size: 4, shape: :hexagon) }.to raise_error(ArgumentError, /unknown shape/)
    end
  end
end
