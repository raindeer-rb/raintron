# frozen_string_literal: true

require 'erb'
require 'fileutils'

module Raintron
  # Renders raintron's ERB templates into a consuming app's directory. Skips files
  # that already exist (so re-running `raintron install` is safe) unless force: true.
  class Generator
    TEMPLATES_ROOT = File.expand_path('../../templates', __dir__)

    def initialize(destination_root: Dir.pwd, force: false, templates_root: TEMPLATES_ROOT)
      @destination_root = destination_root
      @force = force
      @templates_root = templates_root
    end

    # template_path: path under templates/, WITH the .erb suffix (e.g. 'bin/desktop.erb').
    # destination_path: path under destination_root, WITHOUT .erb (e.g. 'bin/desktop').
    # Returns the written path, or nil if skipped.
    def render(template_path, destination_path, vars = {})
      source = File.join(@templates_root, template_path)
      dest = File.join(@destination_root, destination_path)

      if File.exist?(dest) && !@force
        warn "skip #{destination_path} (already exists; pass --force to overwrite)"
        return nil
      end

      content = ERB.new(File.read(source), trim_mode: '-').result_with_hash(vars)

      FileUtils.mkdir_p(File.dirname(dest))
      File.write(dest, content)
      File.chmod(0o755, dest) if File.executable?(source)

      dest
    end
  end
end
