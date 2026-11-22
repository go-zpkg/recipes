# gitlab.com/apparmor/libapparmor — libapparmor, the AppArmor userspace library
# (and libaalogparse, its audit log parser). Step of go-zpkg/recipes#348 (design
# go-zpkg/packages#440): systemd's `apparmor` option (meson.build:1131-1133
# `dependency('libapparmor', version : '>= 2.13')`, option at
# meson_options.txt:409) links it.
#
# ⛔ WRITTEN FROM libraries/libapparmor's OWN configure.ac, autogen.sh,
# Makefile.am, src/Makefile.am, include/Makefile.am and COPYING.LGPL, at 5.0.2 —
# the newest stable tag (gitlab.com/apparmor/apparmor tags, read 2026-11-22:
# v6.0.0-alpha3 is a prerelease, v4.1.8 is the older branch).
# ⛔ NOT BUILT. Builds are suspended by a security hold; what is established is
# the inputs, each traced to a line in the project's own files.
#
# THE SOURCE IS THE WHOLE apparmor TREE, BUILT FROM libraries/libapparmor:
#   The project's signed archive is the tag archive of the monorepo (parser,
#   profiles, utils, the kernel module list and this library). The library
#   builds from libraries/libapparmor (build `working-directory`), and its
#   Makefile.am reaches ../../common (src/Makefile.am:40-41, `include
#   $(COMMONDIR)/Make.rules`; configure.ac:1-2 reads common/Version): the
#   whole archive is needed, not a subdirectory.
#
# NO GENERATED configure IS SHIPPED. The archive is a `git archive` of the tag,
# so the library has configure.ac and Makefile.am only, and autogen.sh:36-43
# runs aclocal, `autoconf --force`, `libtoolize --automake -c --force` and
# `automake -ac`. That is why the build dependencies are autoconf, automake,
# libtool, and:
#   gnu.org/autoconf-archive — configure.ac:101 `m4_ifndef([AX_CHECK_COMPILE_FLAG],
#       [AC_MSG_ERROR(['autoconf-archive' missing])])`; the macro is installed in
#       that recipe's share/aclocal, which aclocal does not search by itself, so
#       ACLOCAL_PATH names it;
#   freedesktop.org/pkg-config — configure.ac:14 `PKG_PROG_PKG_CONFIG` is
#       pkg-config's pkg.m4, in ITS share/aclocal (the same reason);
#   gnu.org/libtool — configure.ac:91 `LT_INIT`, libtool.m4 in its share/aclocal;
#   github.com/westes/flex and gnu.org/bison — configure.ac:11-12
#       `AM_PROG_LEX`, `AC_PROG_YACC`; src/Makefile.am:58 lists grammar.y and
#       scanner.c (from scanner.l, :47-50) as sources;
#   gnu.org/gcc — configure.ac:94 C99 (`AC_PROG_CC_C99`) and :99 `AC_PROG_CXX`
#       (the C++ log-parser test, src/Makefile.am:74).
#
# SWITCHES (configure.ac, each AC_ARG_ENABLE / AC_ARG_WITH there is stated):
#   --enable-debug-output  :19-24  default no — left;
#   --enable-man-pages     :27-38  default YES, and it requires podchecker and
#                          pod2man (:33-37): turned off, no perl-pod toolchain
#                          is a build dependency;
#   --with-python, --with-perl, --with-ruby  :41-74  default no, each needing
#                          SWIG — stated off so a SWIG on the PATH changes nothing.
# `make install` walks SUBDIRS = doc src include swig testsuite
# (Makefile.am:5); with the three bindings and the man pages off, `doc` and
# `swig` install nothing.

summary = "libapparmor: AppArmor userspace library and audit log parser"

# COPYING.LGPL (the file) is the text of the LGPL version 2.1. The "or later"
# is the project's per-file header, NOT read here (see provenance.note).
license = "LGPL-2.1-or-later"

platforms = ["linux"]

versions {
  # Tags are `v5.0.2`, plus `v6.0.0-alpha3` prereleases and a `v4.1.8` branch.
  gitlab = "apparmor/apparmor"
}

distributable {
  # The tag archive, which the project SIGNS: its release page lists the
  # archive's checksum and the detached signature (a generic package, not
  # `<url>.asc`). 5.0.2: 7613191 bytes, `zpkb sourcepin -sig <that URL>`
  # verified the signature, see provenance.note; the digest also equals the
  # one on the release page.
  url              = "https://gitlab.com/apparmor/apparmor/-/archive/v{{version.raw}}/apparmor-v{{version.raw}}.tar.gz"
  strip-components = 1

  sha256 = {
    "5.0.2" = "bef45f228c0bde2f80d9630084e56bd8020b3fc4dfa7ee48a6aca585bb5ea0ed"
  }
}

build {
  dependencies = {
    "gnu.org/make"               = "*"
    "gnu.org/gcc"                = "*"
    "gnu.org/autoconf"           = "*"
    "gnu.org/automake"           = "*"
    "gnu.org/libtool"            = "*"
    "gnu.org/autoconf-archive"   = "*"
    "freedesktop.org/pkg-config" = "*"
    "gnu.org/bison"              = "*"
    "github.com/westes/flex"     = "*"
  }

  working-directory = "libraries/libapparmor"

  env = {
    # aclocal searches only its own prefix; pkg.m4, libtool.m4 and the
    # autoconf-archive macros are in three other prefixes.
    ACLOCAL_PATH = "{{deps.freedesktop.org/pkg-config.prefix}}/share/aclocal:{{deps.gnu.org/libtool.prefix}}/share/aclocal:{{deps.gnu.org/autoconf-archive.prefix}}/share/aclocal"

    ARGS = [
      "--prefix={{prefix}}",
      "--disable-man-pages",
      "--without-python",
      "--without-perl",
      "--without-ruby",
    ]
  }

  script = [
    "sh autogen.sh",
    "./configure $ARGS",
    "make --jobs {{ hw.concurrency }}",
    "make install",
  ]
}

test {
  script = [
    "test -f \"{{prefix}}/include/sys/apparmor.h\"",
    "test -f \"{{prefix}}/include/aalogparse/aalogparse.h\"",
    "test -f \"{{prefix}}/lib/pkgconfig/libapparmor.pc\"",
    "grep -q '^Version: {{version.raw}}' \"{{prefix}}/lib/pkgconfig/libapparmor.pc\"",
    "test -e \"{{prefix}}/lib/libapparmor.so\"",
  ]
}

provenance {
  read = [
    "libraries/libapparmor/configure.ac",         # :1-4 version from common/Version; :11-14 lex, yacc, pkg-config; :19-38 debug, man pages; :41-74 bindings; :101-107 autoconf-archive and flags
    "libraries/libapparmor/autogen.sh",           # :6-30 required tools; :36-43 aclocal, autoconf, libtoolize, automake
    "libraries/libapparmor/Makefile.am",          # :5 SUBDIRS
    "libraries/libapparmor/src/Makefile.am",      # :40-41 ../../common/Make.rules; :43-50 grammar and scanner; :55-63 library and pkgconfig; :33-36 version-info
    "libraries/libapparmor/include/Makefile.am",  # :3-4 aalogparse headers; sys/ subdirectory
    "libraries/libapparmor/COPYING.LGPL",         # :1-2 the LGPL 2.1 text
    "common/Version",                             # 5.0.2
    "libraries/libapparmor/src/libapparmor.pc.in",# :8 Version, :9-10 Cflags, Libs
    "https://gitlab.com/apparmor/apparmor/-/wikis/5.0.2_Signatures",  # the fingerprint the project publishes
    "https://gitlab.com/api/v4/projects/apparmor%2Fapparmor/releases/v5.0.2",  # release assets, checksums
  ]

  consulted = []

  note = <<EOT
  source     https://gitlab.com/apparmor/apparmor/-/archive/v5.0.2/apparmor-v5.0.2.tar.gz
  sha256     bef45f228c0bde2f80d9630084e56bd8020b3fc4dfa7ee48a6aca585bb5ea0ed
             (also the digest the release page publishes for this archive)
  signature  https://gitlab.com/api/v4/projects/4484878/packages/generic/signatures/5.0.2/apparmor-v5.0.2.tar.gz.asc
  signer     3ECDCBA5FB34D254961CC53F6689E64E3D3664BB, AppArmor Development Team
             (AppArmor signing key) <apparmor@lists.ubuntu.com>, signed
             2026-07-13
  fingerprint NAMED BY THE PROJECT: https://gitlab.com/apparmor/apparmor/-/wikis/5.0.2_Signatures
             "The AppArmor signing key has the fingerprint 3ECD CBA5 FB34 D254
             961C C53F 6689 E64E 3D36 64BB". The key file was fetched from
             keyserver.ubuntu.com and checked against that fingerprint.

⚠ A GitLab tag archive is generated on demand: a digest mismatch can mean the
generator changed its compression, not that the content changed. The signature
covers the archive as released.

⛔ NOT BUILT. Unverified: that the per-file headers say "or later" (only
COPYING.LGPL, the LGPL 2.1 text, was read); that the gitlab version source
ignores `v6.0.0-alpha3` and `v4.1.8` and resolves 5.0.2 (zpkb lint checks the
newest is pinned); that `working-directory` relative to the source root works
for a subdirectory the way berkeley-db's `build_unix` does; that gnu.org/gcc
provides g++ for AC_PROG_CXX; that autoconf-archive, libtool and pkg-config
install their macros in share/aclocal as ACLOCAL_PATH assumes; that
libapparmor.pc's baked `prefix=` (src/libapparmor.pc.in:1) is accepted like
any other .pc file in this tree.
EOT
}
