# frozen_string_literal: true

module Raintron
  # Windows .ico container. Vista+ PNG-compressed ICONDIRENTRYs -- valid since Windows
  # Vista, verified this session by building one and confirming `file` reports a
  # well-formed multi-size icon resource.
  module IcoWriter
    DEFAULT_SIZES = [16, 24, 32, 48, 64, 128, 256].freeze

    # entries: [{ size: Integer, png: String }, ...]
    def self.encode(entries:)
      header = [0, 1, entries.size].pack('v3')
      offset = header.bytesize + (16 * entries.size)
      directory = String.new(encoding: Encoding::BINARY)
      data = String.new(encoding: Encoding::BINARY)

      entries.each do |entry|
        size = entry.fetch(:size)
        png = entry.fetch(:png)
        wh = size < 256 ? size : 0 # 0 means 256, per the ICO spec
        directory << [wh, wh, 0, 0, 1, 32, png.bytesize, offset].pack('C4v2V2')
        data << png
        offset += png.bytesize
      end

      header + directory + data
    end
  end
end
