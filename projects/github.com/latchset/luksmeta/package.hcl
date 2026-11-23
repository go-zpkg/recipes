# github.com/latchset/luksmeta — a library and tool to store small pieces of
# metadata (a UUID and up to a few hundred bytes per key slot) in the unused
# space of a LUKS1 header: `luksmeta init|test|save|load|show|wipe|nuke`.
#
# It is here for clevis: clevis' meson.build builds the LUKS bindings
# (clevis-luks-bind, -unlock, -list, ...) only `if libcryptsetup.found() and
# luksmeta.found()` (src/luks/meson.build... the `luksmeta` dependency is read at
# src/luks/meson.build:13), and otherwise warns "Will not install LUKS support
# due to missing dependencies!". So without this package a clevis built here
# would silently lack the LUKS part the batch is for.
#
# ⛔ WRITTEN FROM THE PROJECT'S OWN FILES (configure.ac, Makefile.am,
# test-luksmeta, COPYING) at 11, the newest release (GitHub `releases/latest` is
# v11). v11 carries the fixes for CVE-2025-11568 (the test file's last two blocks
# store an oversized value and expect a refusal). The digest below is computed
# from my own download of luksmeta-11.tar.bz2.
#
# configure.ac:13 requires libcryptsetup >= 1.5.1 through pkg-config; :36-42 find
# a2x and only warn when it is missing, so no manual page is built (asciidoc has
# no recipe). :10 disables the static library.

summary = "luksmeta: store metadata in the LUKS1 header's unused space (library and luksmeta tool)"

# COPYING: the GNU Lesser General Public License, version 2.1 (the file is the
# LGPL-2.1 text; the sources carry "GNU Lesser General Public License ... either
# version 2.1 of the License, or (at your option) any later version").
license = "LGPL-2.1-or-later"

platforms = ["linux"]

versions {
  github = "latchset/luksmeta"
}

dependencies = {
  "gitlab.com/cryptsetup/cryptsetup" = "^2"
}

distributable {
  # The release tarball: it carries the generated `configure`.
  url              = "https://github.com/latchset/luksmeta/releases/download/v{{version.raw}}/luksmeta-{{version.raw}}.tar.bz2"
  strip-components = 1

  # 11, computed from the download.
  sha256 = {
    "11" = "0a9649fec5643cdd33329bda01e1826754e653818b9532464c7dff49af47a3cb"
  }
}

build {
  dependencies = {
    "gnu.org/make"               = "*"
    "freedesktop.org/pkg-config" = "*"
    "gnu.org/gcc"                = "*"
  }

  env = {
    ARGS = [
      "--prefix={{prefix}}",
      "--libdir={{prefix}}/lib",
      "--disable-static",
    ]

    PKG_CONFIG_PATH = "{{deps.gitlab.com/cryptsetup/cryptsetup.prefix}}/lib/pkgconfig"

    # luksmeta and libluksmeta.so link libcryptsetup, found through -L; the
    # directory is also the run-time rpath.
    LDFLAGS = "-L{{deps.gitlab.com/cryptsetup/cryptsetup.prefix}}/lib -Wl,-rpath,{{prefix}}/lib -Wl,-rpath,{{deps.gitlab.com/cryptsetup/cryptsetup.prefix}}/lib"
  }

  script = [
    "./configure $ARGS",
    "make --jobs {{hw.concurrency}}",
    "make install",
  ]
}

provides = [
  "bin/luksmeta",
]

test {
  dependencies = {
    "gitlab.com/cryptsetup/cryptsetup" = "^2"
  }

  script = [
    "test -f {{prefix}}/include/luksmeta.h",
    "test -f {{prefix}}/lib/pkgconfig/luksmeta.pc",
    "test -e {{prefix}}/lib/libluksmeta.so",
    # THE REAL THING, after test-luksmeta: a LUKS1 header in a regular file, an
    # empty luksmeta area, one value stored in slot 0 and read back, then wiped.
    "truncate -s 4M luks.img",
    "printf foo | cryptsetup luksFormat --type luks1 --batch-mode --pbkdf pbkdf2 --pbkdf-force-iterations 1000 luks.img -",
    "if luksmeta test -d luks.img; then exit 1; fi",
    "luksmeta init -f -d luks.img",
    "luksmeta test -d luks.img",
    "printf hi | luksmeta save -s 0 -u 23149359-1b61-4803-b818-774ab730fbec -d luks.img",
    "test \"$(luksmeta show -s 0 -d luks.img)\" = 23149359-1b61-4803-b818-774ab730fbec",
    "test \"$(luksmeta load -s 0 -d luks.img)\" = hi",
    "luksmeta wipe -f -s 0 -d luks.img",
    "if luksmeta load -s 0 -d luks.img; then exit 1; fi",
  ]
}

provenance {
  read = [
    "configure.ac",    # :13 libcryptsetup >= 1.5.1; :36-42 a2x optional
    "test-luksmeta",   # the sequence the test above replays, and the CVE-2025-11568 blocks
    "COPYING",         # the licence text
    "https://github.com/latchset/luksmeta/releases",
  ]

  consulted = []

  note = <<EOT
Built and run on Linux (aarch64, glibc) with the commands of this file, the
libraries from the container's packages; the test sequence was replayed there.

⚠ Nothing beside the tarball was read as a signature; the digest is the one
computed from the download, and a second witness is not available.
EOT
}
