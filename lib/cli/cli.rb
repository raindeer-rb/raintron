# frozen_string_literal: true

require 'trees'
require_relative '../raintron'
require_relative '../generator/generator'
require_relative '../commands/install'
require_relative '../commands/press'
require_relative '../commands/doctor'
require_relative '../commands/icons'

module Raintron
  # `trees`' Trie#match requires the ENTIRE args array to be consumed by one defined
  # path -- it has no concept of trailing/optional args at all (verified directly
  # against ~/dev/trees/lib/trie.rb's #full_match, which fails the whole match if any
  # token is left over). So trees is used only to route the bare verb (a single
  # token); everything after it is handed to the command UNSPLIT, and each command
  # uses OptionParser#parse (non-destructive) to separate its own flags from any
  # positional argument -- OptionParser knows which flags consume a following value
  # (e.g. `--width 900` is two tokens), which a naive "starts with -" split does not.
  module CLI
    extend Trees

    class << self
      attr_accessor :argv
    end

    line('install') do
      summary { 'Wire desktop-app capability into the current Raindeer app.' }
      execute { Commands::Install.run(argv: CLI.argv) }
    end

    line('press') do
      summary { 'Pack the app into a native executable with Tebako.' }
      execute { Commands::Press.run(argv: CLI.argv) }
    end

    line('icons') do
      summary { 'Regenerate app icons (.icns/.ico/.png).' }
      execute { Commands::Icons.run(argv: CLI.argv) }
    end

    line('doctor') do
      summary { 'Check native toolkit prerequisites for webview_ruby.' }
      execute { Commands::Doctor.run }
    end

    singleton_class.send(:alias_method, :dispatch, :run)

    def self.run(argv)
      return usage if argv.empty?

      verb, *rest = argv
      self.argv = rest

      dispatch([verb]) || unknown_command(verb)
    end

    def self.usage
      warn 'usage: raintron <install|press|icons|doctor> [options]'
      exit(1)
    end

    def self.unknown_command(verb)
      warn "raintron: unknown command #{verb.inspect}"
      warn 'Available commands: install, press, icons, doctor'
      exit(1)
    end
  end
end
