# freedesktop.org/xkeyboard-config — the X keyboard configuration database: the
# keycodes, types, compat maps, symbols (layouts) and rules that libxkbcommon
# reads at RUN time. Step 3 of go-zpkg/recipes#348 (design go-zpkg/packages#440):
# systemd's `xkbcommon` option (meson_options.txt:488) links libxkbcommon, and a
# keymap needs this data to compile.
#
# ⛔ WRITTEN FROM THE PROJECT'S OWN FILES (meson.build, meson_options.txt,
# rules/meson.build, symbols/meson.build's neighbours, po/meson.build, COPYING,
# RELEASING.md) at 2.49 — the newest tag: `git ls-remote --tags` of
# gitlab.freedesktop.org/xkeyboard-config/xkeyboard-config lists
# xkeyboard-config-2.49 after 2.48 in VERSION order (read in version order: the
# lexical list puts 2.5 and 2.6 after 2.49), and meson.build:2 says 2.49.
# ⛔ NOT BUILT. Builds are suspended by a security hold; what is established is
# the inputs, each traced to a line in the project's own files.
#
# DATA ONLY, NO LIBRARY. Everything installs under <prefix>/share:
#   share/xkeyboard-config-2/        the database (meson.build:9, :27 `xkb_root`)
#   share/pkgconfig/                 ⛔ NOT lib/pkgconfig: meson.build:13, :31 put
#                                    xkeyboard-config-2.pc (and the legacy
#                                    xkeyboard-config.pc symlink, :38) in
#                                    <datadir>/pkgconfig. A consumer's
#                                    PKG_CONFIG_PATH must name share/pkgconfig.
#   share/X11/xkb -> xkeyboard-config-2   legacy symlink (meson.build:124-130)
#   share/man/man7                   only if xsltproc is on PATH (:56-57, found
#                                    with `required: false`, so it is taken from
#                                    whatever the builder has; not declared here)
#
# OPTIONS (meson_options.txt), every one that chooses:
#   compat-rules (:1) default true: the compatibility rules some legacy
#       clients read; stated true.
#   xorg-rules-symlinks (:5) default false: "xorg" symlinks to the "base" rules;
#       stated false.
#   nls (:9) default TRUE: po/meson.build:1-10 then calls i18n.gettext, which
#       needs msgfmt/xgettext (gettext tools) at build time; no gettext is
#       declared, and the translations only localise layout NAMES in the registry.
#       OFF, so the build does not take gettext from the host.
#   non-latin-layouts-list (:13) default false: would need python yaml and the
#       xkbcli program (meson.build:98-102): not wanted, stated false.
# BUILD REQUIREMENTS read from the files: python >= 3.11 (rules/meson.build:8,
# `python3 -m rules.generator`, standard library only: every import of
# rules/generator was read and none is third-party), and perl for
# rules/xml2lst.pl (`#!/usr/bin/env perl`, find_program at rules/meson.build:17).
# The pytest suite (meson.build:133-158) is taken only when python has pytest;
# it is not installed by this recipe's python and `meson test` is not run.

summary = "xkeyboard-config: the X keyboard configuration database (layouts and rules)"

# COPYING is a collection of permissive notices (the first at COPYING:1-23 is a
# "permission to use, copy, modify, distribute, and sell" notice by several
# holders, then the MIT notices of DEC and others); meson.build:3 declares
# 'MIT/Expat'. Only the first 40 lines of COPYING were read, so the project's own
# declaration is what is carried.
license = "MIT"

platforms = ["linux", "darwin"]

versions {
  # Tags are `xkeyboard-config-2.49`.
  gitlab = "gitlab.freedesktop.org:xkeyboard-config/xkeyboard-config"
  strip  = ["/^xkeyboard-config-/"]
}

distributable {
  # ⚠ A GENERATED ARCHIVE. The x.org release directory carries the SIGNED tarballs
  # of 2.48 and older but NOT 2.49 (HTTP 404 on both the .tar.xz and the .sig,
  # measured 2026-11-22), so the pin is the archive GitLab generates from the
  # tag. A digest of it is only as stable as GitLab's archiver (see the lz4
  # recipe for what that cost elsewhere).
  url              = "https://gitlab.freedesktop.org/xkeyboard-config/xkeyboard-config/-/archive/xkeyboard-config-{{version.raw}}/xkeyboard-config-xkeyboard-config-{{version.raw}}.tar.gz"
  strip-components = 1

  # 1837111 bytes, recorded with `zpkb sourcepin --version 2.49` and reproduced
  # by an independent curl-and-shasum of the same URL (deda99f7…fddd61). Same
  # host: it shows the archive is stable across two requests, not who made it.
  sha256 = {
    "2.49" = "deda99f75a41532db85661cac01793c9b48b5e68a78ecd259fe8b3a7d8fddd61"
  }
}

build {
  dependencies = {
    "mesonbuild.com"             = "*"
    "ninja-build.org"            = "*"
    "freedesktop.org/pkg-config" = "*"
    "python.org"                 = "^3"
    "perl.org"                   = "*"
  }

  env = {
    ARGS = [
      "--prefix={{prefix}}",
      "--libdir={{prefix}}/lib",
      "--sysconfdir=etc",
      "--buildtype=release",
      "--wrap-mode=nofallback",

      "-Dcompat-rules=true",
      "-Dxorg-rules-symlinks=false",
      "-Dnls=false",
      "-Dnon-latin-layouts-list=false",
    ]
  }

  script = [
    "meson setup build $ARGS",
    "meson compile -C build",
    "meson install -C build",
  ]
}

test {
  script = [
    # meson.build:9, :27: the root the .pc names.
    "test -d \"{{prefix}}/share/xkeyboard-config-2/symbols\"",
    "test -f \"{{prefix}}/share/xkeyboard-config-2/symbols/us\"",
    "test -f \"{{prefix}}/share/xkeyboard-config-2/rules/evdev\"",
    "test -f \"{{prefix}}/share/xkeyboard-config-2/rules/base\"",
    # meson.build:13, :31: share/pkgconfig, not lib/pkgconfig.
    "test -f \"{{prefix}}/share/pkgconfig/xkeyboard-config-2.pc\"",
    "grep -F 'xkb_root={{prefix}}/share/xkeyboard-config-2' \"{{prefix}}/share/pkgconfig/xkeyboard-config-2.pc\" >/dev/null",
    # meson.build:124-130: the legacy link.
    "test -L \"{{prefix}}/share/X11/xkb\"",
  ]
}

provenance {
  read = [
    "meson.build",            # :1-4 version 2.49; :9-13 the install directories; :18-42 the pkg-config file and its legacy symlink; :44-53 compat, geometry, keycodes, types; :56-88 the man page (xsltproc); :90-122 python and the non-latin list; :124-130 the legacy X11 symlink
    "meson_options.txt",      # all four options
    "rules/meson.build",      # :8-19 python >= 3.11 and perl; :21-46 the generator run
    "po/meson.build",         # :1 `if get_option('nls')`
    "rules/generator/*.py",   # the imports of every module: standard library only
    "COPYING",                # :1-40 the notices
    "RELEASING.md",           # how a release is made: a tag, and a tarball from `meson dist`
    "https://gitlab.freedesktop.org/xkeyboard-config/xkeyboard-config.git (git ls-remote --tags)",
    "https://www.x.org/releases/individual/data/xkeyboard-config/ (the listing: 2.48 is the last tarball)",
  ]

  consulted = []

  note = <<EOT
  source     https://gitlab.freedesktop.org/xkeyboard-config/xkeyboard-config/-/archive/xkeyboard-config-2.49/xkeyboard-config-xkeyboard-config-2.49.tar.gz
  sha256     deda99f75a41532db85661cac01793c9b48b5e68a78ecd259fe8b3a7d8fddd61

⚠ NO SIGNATURE for 2.49. The signed tarballs on x.org stop at 2.48 (the
directory listing was read; 2.49 answers 404 with and without .sig). The
digest is a cross-check: `zpkb sourcepin` and an independent curl plus
`shasum -a 256` of the same URL agree. GitLab regenerates tag archives, so a
mismatch means a changed archive or a moved tag, to be investigated and not
re-pinned blindly.

⛔ NOT BUILT. Unverified: that python3 on the build's PATH is >= 3.11 (the
recipe asks for `^3` only, like systemd.io); that `python3 -m rules.generator`
finds `rules` through PYTHONPATH as set at rules/meson.build:43; the
`test` block (read from meson.build, not run).
EOT
}
