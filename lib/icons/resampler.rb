# frozen_string_literal: true

module Raintron
  # Pure-arithmetic area-averaging (box) resize -- no image library. Used only for
  # the "bring your own logo" path (the no-source placeholder path renders each size
  # directly, so it never needs to resize anything).
  module Resampler
    def self.resize(rgba:, src_w:, src_h:, dst_w:, dst_h:)
      return rgba if src_w == dst_w && src_h == dst_h

      out = String.new(encoding: Encoding::BINARY)
      dst_h.times do |dst_y|
        y0 = (dst_y * src_h) / dst_h
        y1 = [((dst_y + 1) * src_h) / dst_h, y0 + 1].max
        dst_w.times do |dst_x|
          x0 = (dst_x * src_w) / dst_w
          x1 = [((dst_x + 1) * src_w) / dst_w, x0 + 1].max
          out << average_box(rgba:, src_w:, x_range: x0...x1, y_range: y0...y1)
        end
      end
      out
    end

    def self.average_box(rgba:, src_w:, x_range:, y_range:)
      sums = [0, 0, 0, 0]
      count = 0
      y_range.each do |y|
        x_range.each do |x|
          index = ((y * src_w) + x) * 4
          4.times { |channel| sums[channel] += rgba.getbyte(index + channel) }
          count += 1
        end
      end
      sums.map { |sum| (sum / count.to_f).round }.pack('C4')
    end

    private_class_method :average_box
  end
end
