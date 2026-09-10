# frozen_string_literal: true

require 'optparse'
require 'fileutils'

module Raintron
  module Commands
    # Wires desktop-app capability into the raindeer app in the current directory:
    # bin/desktop, a macOS .app bundle, icons, and a Tebako packing CI workflow.
    # Idempotent -- re-running skips files that already exist unless --force.
    class Install
      DEFAULT_WIDTH = 900
      DEFAULT_HEIGHT = 600

      def self.run(argv: [])
        new.run(argv:)
      end

      def run(argv:)
        options, positional = parse(argv)
        app_name = resolve_app_name(options, positional)
        bundle_dir = "#{camelize(app_name)}.app"
        force = options[:force] || false

        generator = Generator.new(force:)
        render_templates(generator:, app_name:, bundle_dir:, options:)
        install_icons(app_name:, bundle_dir:, source: options[:icon], force:)
        insert_gemfile_guard!

        puts "raintron installed. Run `bundle exec bin/desktop` to launch #{app_name}."
      end

      private

      # OptionParser#parse (non-destructive) returns the leftover non-option
      # arguments -- e.g. a bare app name -- rather than raising or discarding them,
      # unlike a naive "does this token start with -" split (which mishandles any
      # flag that takes a following value, like `--width 900`).
      def parse(argv)
        options = {}
        positional = OptionParser.new do |parser|
          parser.on('--name NAME') { |value| options[:name] = value }
          parser.on('--width N', Integer) { |value| options[:width] = value }
          parser.on('--height N', Integer) { |value| options[:height] = value }
          parser.on('--bundle-id ID') { |value| options[:bundle_id] = value }
          parser.on('--icon PATH') { |value| options[:icon] = value }
          parser.on('--force') { options[:force] = true }
        end.parse(argv)
        [options, positional]
      end

      def resolve_app_name(options, positional)
        name = positional.first || options[:name] || default_name
        return name unless positional.empty? && options[:name].nil? && $stdin.tty?

        prompt_for_name(name)
      end

      def render_templates(generator:, app_name:, bundle_dir:, options:)
        bundle_id = options[:bundle_id] || "dev.local.#{app_name}"
        width = options[:width] || DEFAULT_WIDTH
        height = options[:height] || DEFAULT_HEIGHT

        generator.render('bin/desktop.erb', 'bin/desktop', app_name:, width:, height:)
        generator.render('app/Contents/Info.plist.erb', "#{bundle_dir}/Contents/Info.plist", app_name:, bundle_id:)
        generator.render('app/Contents/MacOS/launch.erb', "#{bundle_dir}/Contents/MacOS/launch", {})
        generator.render('icons/app.desktop.erb', "icons/#{app_name}.desktop", app_name:)
        generator.render('github/workflows/build.yml.erb', '.github/workflows/build.yml',
                         app_name:, ruby_version: detect_ruby_version)
      end

      def default_name
        File.basename(Dir.pwd)
      end

      def prompt_for_name(default)
        print "App name [#{default}]: "
        input = $stdin.gets&.strip
        input.nil? || input.empty? ? default : input
      end

      def camelize(name)
        name.split(/[-_]/).map { |part| part[0].upcase + part[1..].to_s }.join
      end

      def detect_ruby_version
        File.read('.ruby-version').strip
      rescue Errno::ENOENT
        RUBY_VERSION
      end

      def install_icons(app_name:, bundle_dir:, source:, force:)
        icons_dir = File.join(Dir.pwd, 'icons')
        icns_path = File.join(icons_dir, "#{app_name}.icns")

        if File.exist?(icns_path) && !force
          warn "skip icons/#{app_name}.icns (already exists; pass --force to overwrite)"
        else
          IconGenerator.generate(output_dir: icons_dir, basename: app_name, source:)
        end

        resources_dir = "#{bundle_dir}/Contents/Resources"
        FileUtils.mkdir_p(resources_dir)
        FileUtils.cp(icns_path, File.join(resources_dir, 'AppIcon.icns'))
      end

      # Inserts a self-contained toolkit check into the consuming app's Gemfile.
      #
      # This can NOT be a `require 'preflight/preflight'` delegating to Raintron's own
      # Preflight module, however appealing that would be for keeping the check in one
      # place -- verified directly by running this end-to-end: Bundler evaluates the
      # Gemfile DSL top-to-bottom to build the dependency list BEFORE it resolves and
      # activates any gem (including one declared later in the very same Gemfile), so
      # a `require` of another Gemfile-declared gem's code fails every single time,
      # not just occasionally. The logic is duplicated here as inline text instead;
      # `raintron doctor` and this snippet can drift, but a working duplicate beats a
      # DRY snippet that breaks every subsequent `bundle` command.
      #
      # Inserted AFTER any leading comment block (magic comments like
      # `# frozen_string_literal: true` only take effect before the first real line
      # of code -- verified directly: prepending code above one silently disables it
      # for the rest of the file), never before it.
      def insert_gemfile_guard!
        path = 'Gemfile'
        return unless File.exist?(path)

        guard = <<~RUBY
          case RbConfig::CONFIG['host_os']
          when /darwin/
            unless system('xcrun --find clang++', out: File::NULL, err: File::NULL)
              warn 'warning: webview_ruby needs the Xcode Command Line Tools to compile its native ' \\
                   "extension. Install them with: xcode-select --install"
            end
          when /linux/
            unless system('pkg-config --exists gtk+-3.0 webkit2gtk-4.0', out: File::NULL, err: File::NULL)
              warn 'warning: webview_ruby needs GTK3 + WebKit2GTK development headers to compile its ' \\
                   'native extension, e.g.: sudo apt-get install -y build-essential libgtk-3-dev libwebkit2gtk-4.0-dev'
            end
          end

        RUBY
        content = File.read(path)
        return if content.include?(guard)

        lines = content.lines
        insert_at = lines.index { |line| !line.start_with?('#') && !line.strip.empty? } || lines.size
        new_content = (lines[0...insert_at] + [guard] + lines[insert_at..]).join

        File.write(path, new_content)
      end
    end
  end
end
