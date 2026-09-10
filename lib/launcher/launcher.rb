# frozen_string_literal: true

require 'socket'
require 'timeout'

module Raintron
  # Opens a Raindeer app in a native desktop window. The server runs as a real forked
  # child process, not a Thread inside this same process: webview_ruby's native run
  # loop holds Ruby's GVL for as long as the window is open, which would starve a
  # Thread-based server; a separate OS process sidesteps that entirely. `fork` (never
  # Process.spawn of a separate script path) is mandatory once packed by Tebako, since
  # a resolvable script path for a second process to exec doesn't exist inside a
  # packed image -- the whole app lives in a single executable.
  class Launcher
    def initialize(title:, size: [900, 600], host: '127.0.0.1', port: 4133, app_root: Dir.pwd, &server_block)
      @title = title
      @width, @height = size
      @host = host
      @port = port
      @app_root = app_root
      @server_block = server_block
    end

    def run
      start_server
      wait_for_port
      open_window
    ensure
      stop_server
    end

    # Public (and independently callable) so the server half can be exercised
    # headlessly in tests, with no window and no webview_ruby involved at all.
    def start_server
      # Set before fork, unconditionally (not just when packed): the child inherits
      # it via fork's memory copy, and Shims::PwdOverride uses it to answer Dir.pwd
      # correctly regardless of what directory bin/desktop was actually launched from.
      ENV['RAINTRON_APP_ROOT'] ||= @app_root
      @pid = fork do
        Raintron::Shims.apply!(packed: Raintron.packed?)
        @server_block.call
      end
    end

    def wait_for_port
      Timeout.timeout(10) do
        loop do
          TCPSocket.new(@host, @port).close
          break
        rescue Errno::ECONNREFUSED
          sleep 0.05
        end
      end
    end

    def open_window
      # Required only here, only in the parent, only after fork: macOS's Cocoa/WebKit
      # frameworks (which this pulls in) are not fork-safe, so the child must never
      # have loaded them.
      require 'webview_ruby'

      webview = WebviewRuby::Webview.new
      webview.set_title(@title)
      webview.set_size(@width, @height)
      webview.navigate("http://#{@host}:#{@port}/")
      webview.run
      webview.destroy
    end

    def stop_server
      return unless @pid

      Process.kill('TERM', @pid)
      Process.wait(@pid)
    rescue Errno::ESRCH, Errno::ECHILD
      nil
    end
  end
end
