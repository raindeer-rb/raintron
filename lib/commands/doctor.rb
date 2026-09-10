# frozen_string_literal: true

require 'stringio'
require_relative '../preflight/preflight'

module Raintron
  module Commands
    # Runs the native-toolkit preflight check on demand, with explicit pass/fail
    # framing (Preflight.check! itself only warns on failure and is silent on
    # success, since it's designed to run quietly at Gemfile-eval time).
    class Doctor
      def self.run
        new.run
      end

      def run
        warnings = capture_warnings { Preflight.check! }

        if warnings.empty?
          puts 'raintron doctor: OK -- native toolkit prerequisites for webview_ruby look good.'
        else
          warnings.each { |warning| warn warning }
          exit(1)
        end
      end

      private

      def capture_warnings
        original = $stderr
        $stderr = StringIO.new
        yield
        $stderr.string.split("\n\n").reject(&:empty?)
      ensure
        $stderr = original
      end
    end
  end
end
