# frozen_string_literal: true

require 'optparse'
require 'fileutils'

module Raintron
  module Commands
    # Wraps `tebako press` with sensible defaults, so consumers don't need to
    # memorize its flags. Validated this session against a real pressed build that
    # boots and serves HTTP 200.
    class Press
      DEFAULT_OUTPUT_DIR = 'dist'

      def self.run(argv: [])
        new.run(argv:)
      end

      def run(argv:)
        options = parse(argv)

        abort_unless_tebako_available!
        abort_unless_entry_point_exists!

        ruby_version = options[:ruby] || detect_ruby_version
        output = options[:output] || default_output

        FileUtils.mkdir_p(File.dirname(output))

        command = [
          'tebako', 'press',
          '-r', '.',
          '-e', 'bin/desktop',
          '-o', output,
          '-R', ruby_version,
          '--format', 'dwarfs'
        ]

        warn_if_windows

        puts "$ #{command.join(' ')}"
        exit(1) unless system(*command)
      end

      private

      def parse(argv)
        options = {}
        OptionParser.new do |parser|
          parser.on('-R VERSION', '--ruby VERSION') { |value| options[:ruby] = value }
          parser.on('-o PATH', '--output PATH') { |value| options[:output] = value }
        end.parse(argv)
        options
      end

      def abort_unless_tebako_available!
        return if system('which tebako', out: File::NULL, err: File::NULL)

        warn 'tebako is not on PATH. Install it first: https://tebako.org/install.sh'
        exit(1)
      end

      def abort_unless_entry_point_exists!
        return if File.exist?('bin/desktop')

        warn 'bin/desktop not found. Run `raintron install` first.'
        exit(1)
      end

      def detect_ruby_version
        return File.read('.ruby-version').strip if File.exist?('.ruby-version')
        return tool_versions_ruby if File.exist?('.tool-versions')

        RUBY_VERSION
      rescue Errno::ENOENT
        RUBY_VERSION
      end

      def tool_versions_ruby
        line = File.readlines('.tool-versions').find { |l| l.start_with?('ruby ') }
        line ? line.split[1] : RUBY_VERSION
      end

      def default_output
        app_name = File.basename(Dir.pwd)
        os = case RbConfig::CONFIG['host_os']
             when /darwin/ then 'macos'
             when /linux/ then 'linux'
             when /mswin|mingw|cygwin/ then 'windows'
             else RbConfig::CONFIG['host_os']
             end
        ext = os == 'windows' ? '.exe' : ''
        File.join(DEFAULT_OUTPUT_DIR, "#{app_name}-#{os}#{ext}")
      end

      def warn_if_windows
        return unless RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/

        warn 'warning: Tebako\'s Windows release leg is still "in flight" upstream, and ' \
             "webview_ruby's own native-extension build has no Windows path at all today. " \
             'This press is not expected to succeed yet.'
      end
    end
  end
end
