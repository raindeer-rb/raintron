# frozen_string_literal: true

require 'tmpdir'
require_relative '../../../lib/generator/generator'

RSpec.describe Raintron::Generator do
  around do |example|
    Dir.mktmpdir do |dir|
      @tmp = dir
      example.run
    end
  end

  subject(:generator) { described_class.new(destination_root: @tmp) }

  describe '#render' do
    it 'renders a template with the given vars and returns the written path' do
      path = generator.render('bin/desktop.erb', 'bin/desktop', app_name: 'Demo', width: 800, height: 500)

      expect(path).to eq(File.join(@tmp, 'bin/desktop'))
      content = File.read(path)
      expect(content).to include("title: 'Demo'")
      expect(content).to include('size: [800, 500]')
    end

    it 'makes the generated file executable when the template itself is executable' do
      path = generator.render('bin/desktop.erb', 'bin/desktop', app_name: 'Demo', width: 800, height: 500)
      expect(File.executable?(path)).to be true
    end

    it 'does not make the generated file executable when the template is not' do
      path = generator.render('app/Contents/Info.plist.erb', 'App.app/Contents/Info.plist',
                              app_name: 'Demo', bundle_id: 'dev.local.demo')
      expect(File.executable?(path)).to be false
    end

    it 'skips (and returns nil) when the destination already exists and force: false' do
      generator.render('bin/desktop.erb', 'bin/desktop', app_name: 'First', width: 1, height: 1)
      result = generator.render('bin/desktop.erb', 'bin/desktop', app_name: 'Second', width: 2, height: 2)

      expect(result).to be_nil
      expect(File.read(File.join(@tmp, 'bin/desktop'))).to include("title: 'First'")
    end

    it 'overwrites the destination when force: true' do
      generator.render('bin/desktop.erb', 'bin/desktop', app_name: 'First', width: 1, height: 1)
      forcing = described_class.new(destination_root: @tmp, force: true)
      forcing.render('bin/desktop.erb', 'bin/desktop', app_name: 'Second', width: 2, height: 2)

      expect(File.read(File.join(@tmp, 'bin/desktop'))).to include("title: 'Second'")
    end

    it 'creates intermediate directories as needed' do
      path = generator.render('icons/app.desktop.erb', 'deeply/nested/dir/app.desktop', app_name: 'Demo')
      expect(File.exist?(path)).to be true
    end
  end
end
