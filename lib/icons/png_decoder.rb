# frozen_string_literal: true

require 'zlib'

module Raintron
  # Decodes a PNG into raw RGBA bytes, for the "bring your own logo" path. Pure Ruby,
  # stdlib Zlib only. Scoped to what a real-world logo export needs: 8-bit RGB/RGBA,
  # non-interlaced. Anything else (16-bit, palette, Adam7 interlacing, or a non-PNG
  # file entirely -- including JPEG, whose decode is not feasibly zero-dependency)
  # raises Raintron::UnsupportedSourceError with a clear message rather than silently
  # producing a wrong image.
  module PngDecoder
    SIGNATURE = "\x89PNG\r\n\x1a\n".b
    JPEG_MAGIC = "\xff\xd8\xff".b

    def self.decode(bytes)
      raise_unless_png!(bytes)

      chunks = read_chunks(bytes)
      ihdr = chunks.find { |type, _| type == 'IHDR' }
      raise Raintron::UnsupportedSourceError, 'PNG has no IHDR chunk' unless ihdr

      width, height, channels = decode_ihdr(ihdr[1])

      idat = chunks.select { |type, _| type == 'IDAT' }.map { |_, data| data }.join
      raw = Zlib::Inflate.inflate(idat)

      { width:, height:, rgba: unfilter(raw:, width:, height:, channels:) }
    end

    def self.raise_unless_png!(bytes)
      return if bytes.byteslice(0, 8) == SIGNATURE

      if bytes.byteslice(0, 3) == JPEG_MAGIC
        raise Raintron::UnsupportedSourceError,
              'JPEG sources are not supported (decoding JPEG is not feasible without a real dependency). ' \
              'Convert your logo to PNG first, then pass that.'
      end

      raise Raintron::UnsupportedSourceError, 'not a PNG file -- convert your logo to PNG first, then pass that.'
    end

    def self.decode_ihdr(ihdr_data)
      width, height, bit_depth, color_type, _compression, _filter, interlace = ihdr_data.unpack('N2C5')

      unless bit_depth == 8 && [2, 6].include?(color_type) && interlace.zero?
        raise Raintron::UnsupportedSourceError,
              "unsupported PNG (bit depth #{bit_depth}, color type #{color_type}, interlace #{interlace}) -- " \
              'only 8-bit RGB or RGBA, non-interlaced PNGs are supported. Convert your source image first ' \
              '(e.g. re-export as a plain 8-bit PNG).'
      end

      [width, height, color_type == 6 ? 4 : 3]
    end

    def self.read_chunks(bytes)
      chunks = []
      offset = 8
      while offset < bytes.bytesize
        length = bytes.byteslice(offset, 4).unpack1('N')
        type = bytes.byteslice(offset + 4, 4)
        data = bytes.byteslice(offset + 8, length)
        chunks << [type, data]
        offset += 8 + length + 4 # + 4 for the CRC we don't verify
        break if type == 'IEND'
      end
      chunks
    end

    # Reverses PNG's per-scanline filtering (None/Sub/Up/Average/Paeth -- filter types
    # 0-4) to recover raw pixel bytes, then expands RGB to RGBA if needed so every
    # other module in this gem can assume 4 bytes/pixel.
    def self.unfilter(raw:, width:, height:, channels:)
      stride = width * channels
      prior = Array.new(stride, 0)
      out = Array.new(height * stride)
      pos = 0

      height.times do |row|
        filter_type = raw.getbyte(pos)
        pos += 1
        current = raw.byteslice(pos, stride).bytes
        pos += stride

        recon = reconstruct_row(filter_type:, current:, prior:, bpp: channels, stride:)
        out[row * stride, stride] = recon
        prior = recon
      end

      to_rgba(out, channels)
    end

    def self.reconstruct_row(filter_type:, current:, prior:, bpp:, stride:)
      recon = Array.new(stride)
      stride.times do |index|
        left = index >= bpp ? recon[index - bpp] : 0
        above = prior[index]
        corner = index >= bpp ? prior[index - bpp] : 0
        recon[index] = (current[index] + predictor(filter_type, left, above, corner)) & 0xff
      end
      recon
    end

    def self.predictor(filter_type, left, above, corner)
      case filter_type
      when 0 then 0
      when 1 then left
      when 2 then above
      when 3 then (left + above) / 2
      when 4 then paeth(left, above, corner)
      else raise Raintron::UnsupportedSourceError, "unsupported PNG filter type #{filter_type}"
      end
    end

    def self.paeth(left, above, corner)
      base = left + above - corner
      diff_left = (base - left).abs
      diff_above = (base - above).abs
      diff_corner = (base - corner).abs

      return left if diff_left <= diff_above && diff_left <= diff_corner
      return above if diff_above <= diff_corner

      corner
    end

    def self.to_rgba(bytes_array, channels)
      return bytes_array.pack('C*') if channels == 4

      rgba = String.new(encoding: Encoding::BINARY)
      bytes_array.each_slice(3) { |r, g, b| rgba << [r, g, b, 255].pack('C4') }
      rgba
    end

    private_class_method :raise_unless_png!, :decode_ihdr, :read_chunks, :unfilter, :reconstruct_row, :predictor,
                         :paeth, :to_rgba
  end
end
