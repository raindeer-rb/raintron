# frozen_string_literal: true

require_relative 'version'
require_relative 'launcher/launcher'
require_relative 'shims/shims'
require_relative 'icons/icon_generator'
require_relative 'app_config/app_config'

# Merely requiring 'raintron' (i.e. having it in a Gemfile) applies zero shims and
# never requires 'webview_ruby' -- both only happen inside Launcher#run, and the
# shims only inside the forked server child. A plain `rain server` dev workflow with
# raintron in the Gemfile is unaffected by its presence; see lib/shims/shims.rb.
module Raintron
  class Error < StandardError; end
  class UnsupportedSourceError < Error; end

  def self.launch(**kwargs, &server_block)
    Launcher.new(**kwargs, &server_block).run
  end

  def self.packed?
    Shims.packed?
  end
end
