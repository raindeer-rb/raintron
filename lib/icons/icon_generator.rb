# frozen_string_literal: true

require 'fileutils'
require_relative 'png_writer'
require_relative 'png_decoder'
require_relative 'resampler'
require_relative 'renderer'
require_relative 'ico_writer'
require_relative 'icns_writer'

module Raintron
  # Orchestrates the icon writers: renders (or decodes+resizes) every distinct pixel
  # size any format needs exactly once, then hands the result to each format's writer.
  class IconGenerator
    # The union of every size IcnsWriter, IcoWriter, and the single Linux PNG need.
    ALL_SIZES = [16, 24, 32, 48, 64, 128, 256, 512, 1024].freeze
    LINUX_PNG_SIZE = 512

    def self.generate(output_dir:, basename: 'icon', source: nil, **render_opts)
      new(source:, **render_opts).write_all(dir: output_dir, basename:)
    end

    def initialize(source: nil, background: [0, 152, 252, 255], foreground: [255, 255, 255, 255], shape: :circle)
      @source = source
      @background = background
      @foreground = foreground
      @shape = shape
    end

    def write_all(dir:, basename: 'icon')
      FileUtils.mkdir_p(dir)
      pngs = rendered_pngs

      paths = {}

      paths[:icns] = File.join(dir, "#{basename}.icns")
      File.binwrite(paths[:icns], IcnsWriter.encode(pngs_by_size: pngs))

      paths[:ico] = File.join(dir, "#{basename}.ico")
      entries = IcoWriter::DEFAULT_SIZES.map { |size| { size:, png: pngs.fetch(size) } }
      File.binwrite(paths[:ico], IcoWriter.encode(entries:))

      paths[:png] = File.join(dir, "#{basename}.png")
      File.binwrite(paths[:png], pngs.fetch(LINUX_PNG_SIZE))

      paths
    end

    private

    def rendered_pngs
      @rendered_pngs ||= ALL_SIZES.to_h { |size| [size, PngWriter.encode(width: size, height: size, rgba: rgba_for(size))] }
    end

    def rgba_for(size)
      return Renderer.render(size:, background: @background, foreground: @foreground, shape: @shape) unless @source

      Resampler.resize(rgba: decoded_source[:rgba], src_w: decoded_source[:width], src_h: decoded_source[:height],
                       dst_w: size, dst_h: size)
    end

    def decoded_source
      @decoded_source ||= PngDecoder.decode(File.binread(@source))
    end
  end
end
