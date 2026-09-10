# frozen_string_literal: true

require 'tmpdir'
require_relative '../../../lib/commands/press'

RSpec.describe Raintron::Commands::Press do
  around do |example|
    Dir.mktmpdir do |dir|
      @tmp = dir
      Dir.chdir(dir) { example.run }
    end
  end

  def stub_tebako_present(present:)
    allow_any_instance_of(described_class).to receive(:system)
      .with('which tebako', anything).and_return(present)
  end

  describe '#run' do
    it 'aborts with a clear message when tebako is not on PATH' do
      stub_tebako_present(present: false)

      expect { described_class.run(argv: []) }.to raise_error(SystemExit)
    end

    it 'aborts with a clear message when bin/desktop does not exist' do
      stub_tebako_present(present: true)

      expect { described_class.run(argv: []) }.to raise_error(SystemExit)
    end

    it 'resolves the ruby version from .ruby-version' do
      stub_tebako_present(present: true)
      FileUtils.mkdir_p('bin')
      File.write('bin/desktop', '')
      File.write('.ruby-version', "3.4.2\n")
      command = nil
      allow_any_instance_of(described_class).to receive(:system) do |_, *args|
        command = args if args.first == 'tebako'
        true
      end

      described_class.run(argv: [])

      expect(command).to include('-R', '3.4.2')
    end

    it 'lets --ruby override the detected version' do
      stub_tebako_present(present: true)
      FileUtils.mkdir_p('bin')
      File.write('bin/desktop', '')
      File.write('.ruby-version', "3.4.2\n")
      command = nil
      allow_any_instance_of(described_class).to receive(:system) do |_, *args|
        command = args if args.first == 'tebako'
        true
      end

      described_class.run(argv: ['--ruby', '3.3.0'])

      expect(command).to include('-R', '3.3.0')
    end

    it 'builds the expected default output path' do
      stub_tebako_present(present: true)
      FileUtils.mkdir_p('bin')
      File.write('bin/desktop', '')
      command = nil
      allow_any_instance_of(described_class).to receive(:system) do |_, *args|
        command = args if args.first == 'tebako'
        true
      end

      described_class.run(argv: [])

      expect(command[command.index('-o') + 1]).to match(%r{dist/#{File.basename(@tmp)}-})
    end
  end
end
