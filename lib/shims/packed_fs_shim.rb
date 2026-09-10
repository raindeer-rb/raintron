# frozen_string_literal: true

# Tebako's packed virtual filesystem interposes regular file I/O (open/read/stat) but
# not chdir(2) -- gems that Dir.chdir into their own lib directory just to Dir.glob
# relative to it (e.g. low_type's adapter discovery) get ENOENT for a path that
# plainly exists. Fall back to running the block without actually changing directory:
# every current caller of this pattern only globs for optional plugin files that don't
# ship anyway, so the glob coming up empty either way is a no-op, not a behavior change.
module Raintron
  module ChdirFallback
    def chdir(dir = nil, &block)
      return super unless block

      super
    rescue Errno::ENOENT
      block.call(dir)
    end
  end
end

Dir.singleton_class.prepend(Raintron::ChdirFallback)

# Prism.parse_file reads the target file natively (C extension), bypassing whatever
# path Tebako interposes for Ruby-level File/require reads -- it ENOENTs on packed
# paths that `require`/`require_relative` load from just fine elsewhere in the same
# process. low_type's `lowkey` uses it to introspect a gem's own source at load time.
# Fall back to reading through Ruby's File (which the packed image does support) and
# parsing that string instead; Prism.parse and Prism.parse_file return the same
# Prism::ParseResult shape for identical source, so this is a transparent substitution.
require 'prism'

module Raintron
  module PrismParseFileFallback
    def parse_file(filepath, **options)
      super
    rescue Errno::ENOENT
      parse(File.binread(filepath), **options)
    end
  end
end

Prism.singleton_class.prepend(Raintron::PrismParseFileFallback)

# Tebako doesn't support chdir(2) into any packed path, including the app's own root
# (real chdir there ENOENTs same as anywhere else) -- but raindeer's boot.rb builds
# config/config.yaml's path from Dir.pwd, assuming cwd == app root. Rather than actually
# changing directory, report the app root as Dir.pwd's answer whenever the entry point
# has told us (via RAINTRON_APP_ROOT) what it is; regular file reads against that path
# already work fine (require/require_relative use them throughout), so this makes
# Dir.pwd-relative path math resolve correctly without needing real chdir at all.
#
# Launcher sets RAINTRON_APP_ROOT unconditionally, in both packed and normal dev runs
# (it's simply "what is the app's own root", not a packed-only concept -- it also makes
# bin/desktop robust to being launched from a cwd other than the project root even
# without Tebako involved). Because of that, this override can't double as the signal
# for Shims.packed? the way an earlier draft assumed -- see shims.rb.
module Raintron
  module PwdOverride
    def pwd
      ENV['RAINTRON_APP_ROOT'] || super
    end
  end
end

Dir.singleton_class.prepend(Raintron::PwdOverride)
