# frozen_string_literal: true

require 'io/console'

# raindeer's LowFrame calls IO.console.winsize unconditionally to size its terminal
# animation. IO.console is nil with no controlling tty (e.g. launched from Finder/Dock
# as a .app, or spawned by webview's bin/desktop), which crashes boot. Fall back to a
# fixed size in that case; a real terminal's console is used untouched otherwise.
module Raintron
  module ConsoleShim
    FakeConsole = Struct.new(:winsize)

    def console(*args)
      super || FakeConsole.new([40, 120])
    end
  end
end

IO.singleton_class.prepend(Raintron::ConsoleShim)
