# frozen_string_literal: true

require_relative 'lib/version'

Gem::Specification.new do |spec|
  spec.name = 'raintron'
  spec.version = Raintron::VERSION
  spec.authors = ['maedi']
  spec.email = ['maediprichard@gmail.com']

  spec.summary = 'Electron for Ruby: ship a Raindeer app as a native desktop app.'
  spec.description = <<~TEXT
    Raintron wraps a Raindeer web app in a native desktop window (via webview_ruby) and#{' '}
    packages it into a single cross-platform executable (via Tebako). Add it to an existing#{' '}
    Raindeer app's Gemfile, run `raintron install`, and `bin/desktop` opens your app in a#{' '}
    window instead of a browser tab.
  TEXT

  spec.required_ruby_version = '>= 3.3.0'
  spec.homepage = 'https://github.com/raindeer-rb/raintron'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage

  spec.license = 'MPL-2.0'

  # Dir.chdir-for-glob is safe here even though lib/shims/packed_fs_shim.rb patches around this
  # exact pattern failing elsewhere: that patch is for chdir(2) failing *inside a Tebako-packed
  # virtual filesystem at runtime*. A gemspec only ever evaluates at `gem build`/`bundle install`
  # time, on an ordinary filesystem -- Tebako packs the already-installed gem's files, it never
  # re-evaluates the gemspec inside the packed image. Don't "fix" this to work around a bug that
  # can't happen here.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir.glob('{lib,bin,templates}/**/*').select { |f| File.file?(f) }
  end
  spec.require_paths = ['lib']

  spec.bindir = 'bin'
  spec.executables = ['raintron']

  spec.add_dependency 'raindeer'
  spec.add_dependency 'trees'
  spec.add_dependency 'webview_ruby'
end
