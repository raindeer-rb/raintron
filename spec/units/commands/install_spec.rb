# frozen_string_literal: true

require 'tmpdir'
require_relative '../../../lib/generator/generator'
require_relative '../../../lib/commands/install'

RSpec.describe Raintron::Commands::Install do
  around do |example|
    Dir.mktmpdir do |dir|
      @tmp = dir
      Dir.chdir(dir) { example.run }
    end
  end

  def write_gemfile(content = "# frozen_string_literal: true\n\nsource 'https://rubygems.org'\n")
    File.write('Gemfile', content)
  end

  describe '#run' do
    it 'writes bin/desktop, the .app bundle, icons, and the CI workflow' do
      write_gemfile
      described_class.run(argv: ['demo_app'])

      expect(File).to exist('bin/desktop')
      expect(File).to exist('DemoApp.app/Contents/Info.plist')
      expect(File).to exist('DemoApp.app/Contents/MacOS/launch')
      expect(File).to exist('DemoApp.app/Contents/Resources/AppIcon.icns')
      expect(File).to exist('icons/demo_app.icns')
      expect(File).to exist('icons/demo_app.ico')
      expect(File).to exist('icons/demo_app.png')
      expect(File).to exist('icons/demo_app.desktop')
      expect(File).to exist('.github/workflows/build.yml')
    end

    it 'uses the positional name over the directory basename' do
      write_gemfile
      described_class.run(argv: ['custom_name'])
      expect(File.read('bin/desktop')).to include("title: 'custom_name'")
    end

    it 'falls back to the directory basename when no name is given and stdin is not a tty' do
      write_gemfile
      allow($stdin).to receive(:tty?).and_return(false)
      described_class.run(argv: [])
      expect(File.read('bin/desktop')).to include("title: '#{File.basename(@tmp)}'")
    end

    it 'inserts the Gemfile guard after the magic comment, not before it' do
      write_gemfile
      described_class.run(argv: ['demo_app'])

      lines = File.readlines('Gemfile')
      expect(lines.first).to eq("# frozen_string_literal: true\n")
      expect(lines[1..].join).to include("RbConfig::CONFIG['host_os']")
    end

    it 'does not duplicate the Gemfile guard on a second run' do
      write_gemfile
      described_class.run(argv: ['demo_app'])
      described_class.run(argv: ['demo_app'])

      expect(File.read('Gemfile').scan("RbConfig::CONFIG['host_os']").size).to eq(1)
    end

    it 'skips existing files on a second run without --force' do
      write_gemfile
      described_class.run(argv: ['demo_app'])
      File.write('bin/desktop', 'untouched')

      described_class.run(argv: ['demo_app'])

      expect(File.read('bin/desktop')).to eq('untouched')
    end

    it 'overwrites existing files when --force is given' do
      write_gemfile
      described_class.run(argv: ['demo_app'])
      File.write('bin/desktop', 'stale')

      described_class.run(argv: ['demo_app', '--force'])

      expect(File.read('bin/desktop')).not_to eq('stale')
    end

    it 'respects a custom --width' do
      write_gemfile
      described_class.run(argv: ['demo_app', '--width', '1234'])
      expect(File.read('bin/desktop')).to include('size: [1234, 600]')
    end
  end
end
