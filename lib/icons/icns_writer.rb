# frozen_string_literal: true

module Raintron
  # Apple .icns container -- replaces shelling out to `iconutil`. Format: magic "icns"
  # + big-endian u32 total length, then chunks of (4-byte OSType + big-endian u32
  # chunk length INCLUDING this 8-byte header + a raw PNG payload). Modern macOS
  # accepts PNG payloads in these slots (cited: Wikipedia's Apple Icon Image Format
  # page, hexbase.dev, mdsteele/rust-icns, Pillow's IcnsImagePlugin -- there's no
  # official public Apple spec).
  #
  # This exact type/size table replicates `iconutil -c icns`'s own .iconset mapping.
  # An earlier draft omitted the icp4/icp5 @1x slots (16px/32px); a real regression
  # (electron-builder#9940) shows that omission renders broken/scrambled icons in
  # Finder list view and Trash at small sizes, so they're included here deliberately.
  module IcnsWriter
    SIZE_MAP = [
      ['icp4', 16],  # 16@1x
      ['ic11', 32],  # 16@2x
      ['icp5', 32],  # 32@1x
      ['ic12', 64],  # 32@2x
      ['ic07', 128], # 128@1x
      ['ic13', 256], # 128@2x
      ['ic08', 256], # 256@1x
      ['ic14', 512], # 256@2x
      ['ic09', 512], # 512@1x
      ['ic10', 1024] # 512@2x
    ].freeze

    # pngs_by_size: { pixel_size => png_bytes }
    def self.encode(pngs_by_size:)
      body = String.new(encoding: Encoding::BINARY)
      SIZE_MAP.each do |type, size|
        png = pngs_by_size.fetch(size)
        body << type.b
        body << [8 + png.bytesize].pack('N')
        body << png
      end

      'icns'.b + [8 + body.bytesize].pack('N') + body
    end
  end
end
