# frozen_string_literal: true

RSpec.describe Raintron do
  # The core safety property this gem promises: a plain `rain server` dev workflow
  # must be completely unaffected by raintron merely being in the Gemfile. Shims and
  # webview_ruby only ever load from inside Launcher#run's forked child.
  it 'never loads webview_ruby merely by being required' do
    expect($LOADED_FEATURES.grep(/webview_ruby/)).to be_empty
  end

  it 'never applies shims merely by being required (packed_fs_shim.rb never loads)' do
    expect($LOADED_FEATURES.grep(/packed_fs_shim/)).to be_empty
  end

  describe '.packed?' do
    it 'delegates to Shims.packed?' do
      allow(Raintron::Shims).to receive(:packed?).and_return(true)
      expect(described_class.packed?).to be true
    end
  end
end
