# frozen_string_literal: true

require 'zlib'

module Raintron
  # Encodes raw RGBA pixel bytes as a PNG. Stdlib Zlib only -- no image library.
  module PngWriter
    SIGNATURE = "\x89PNG\r\n\x1a\n".b

    # rgba: binary String, width*height*4 bytes, row-major top-to-bottom, R,G,B,A.
    def self.encode(width:, height:, rgba:)
      ihdr = [width, height, 8, 6, 0, 0, 0].pack('N2C5')
      idat = Zlib::Deflate.deflate(filter_scanlines(width:, height:, rgba:), Zlib::BEST_COMPRESSION)

      SIGNATURE + chunk('IHDR', ihdr) + chunk('IDAT', idat) + chunk('IEND', ''.b)
    end

    # Filter type 0 (None) on every scanline: PNG requires a 1-byte filter-type prefix
    # per row even when no filtering is applied.
    def self.filter_scanlines(width:, height:, rgba:)
      row_bytes = width * 4
      raw = String.new(encoding: Encoding::BINARY)
      height.times do |y|
        raw << "\x00".b
        raw << rgba.byteslice(y * row_bytes, row_bytes)
      end
      raw
    end

    def self.chunk(type, data)
      type_and_data = type.b + data.b
      [data.bytesize].pack('N') + type_and_data + [Zlib.crc32(type_and_data)].pack('N')
    end

    private_class_method :filter_scanlines, :chunk
  end
end
