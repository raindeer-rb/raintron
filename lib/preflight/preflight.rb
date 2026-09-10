# frozen_string_literal: true

module Raintron
  # webview_ruby compiles a native C++ extension against the platform's GUI toolkit
  # (Cocoa+WebKit / GTK3+WebKit2GTK / MSHTML). Missing headers otherwise surface as a
  # cryptic mkmf/rake compile failure deep in `bundle install` output, so check for the
  # actual prerequisite upfront and say plainly what's missing. `raintron install`
  # inserts a two-line `require 'preflight/preflight'; Raintron::Preflight.check!` at
  # the top of the consuming app's Gemfile (not a copy-pasted version of this logic),
  # so improvements here reach every consumer via `bundle update` rather than needing
  # every app's Gemfile hand-edited again.
  module Preflight
    def self.check!
      case RbConfig::CONFIG['host_os']
      when /darwin/ then check_macos
      when /linux/ then check_linux
      end
    end

    def self.check_macos
      return if system('xcrun --find clang++', out: File::NULL, err: File::NULL)

      warn <<~MSG
        warning: webview_ruby needs the Xcode Command Line Tools to compile its native
        extension (Cocoa/WebKit bindings). Install them with:
          xcode-select --install
      MSG
    end

    def self.check_linux
      return if system('pkg-config --exists gtk+-3.0 webkit2gtk-4.0', out: File::NULL, err: File::NULL)

      warn <<~MSG
        warning: webview_ruby needs GTK3 + WebKit2GTK development headers to compile its
        native extension. Install them first, e.g.:
          Debian/Ubuntu: sudo apt-get install -y build-essential libgtk-3-dev libwebkit2gtk-4.0-dev
          Fedora:        sudo dnf install -y gcc-c++ gtk3-devel webkit2gtk3-devel
      MSG
    end

    private_class_method :check_macos, :check_linux
  end
end
