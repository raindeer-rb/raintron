# frozen_string_literal: true

module Raintron
  # Procedural placeholder icon (no source image): a shape rendered directly at each
  # target size, so no resizing is ever needed for this path.
  module Renderer
    def self.render(size:, background: [0, 152, 252, 255], foreground: [255, 255, 255, 255], shape: :circle)
      background_bytes = background.pack('C4')
      foreground_bytes = foreground.pack('C4')

      rgba = String.new(encoding: Encoding::BINARY)
      size.times do |row|
        size.times do |col|
          rgba << (inside?(shape, col, row, size) ? foreground_bytes : background_bytes)
        end
      end
      rgba
    end

    def self.inside?(shape, col, row, size)
      center = (size - 1) / 2.0

      case shape
      when :circle
        radius = size * 0.32
        dcol = col - center
        drow = row - center
        ((dcol * dcol) + (drow * drow)) <= (radius * radius)
      when :square
        half = size * 0.32
        (col - center).abs <= half && (row - center).abs <= half
      else
        raise ArgumentError, "unknown shape: #{shape.inspect}"
      end
    end

    private_class_method :inside?
  end
end
