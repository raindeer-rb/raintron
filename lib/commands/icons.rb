# frozen_string_literal: true

require 'optparse'

module Raintron
  module Commands
    # Regenerates icons standalone (without the rest of `raintron install`), e.g.
    # after swapping in a new source logo.
    class Icons
      def self.run(argv: [])
        new.run(argv:)
      end

      def run(argv:)
        options, positional = parse(argv)
        name = positional.first || options[:name] || File.basename(Dir.pwd)

        paths = IconGenerator.generate(output_dir: 'icons', basename: name, source: options[:source])
        puts "Wrote #{paths.values.join(', ')}"
      end

      private

      def parse(argv)
        options = {}
        positional = OptionParser.new do |parser|
          parser.on('--name NAME') { |value| options[:name] = value }
          parser.on('--source PATH') { |value| options[:source] = value }
        end.parse(argv)
        [options, positional]
      end
    end
  end
end
