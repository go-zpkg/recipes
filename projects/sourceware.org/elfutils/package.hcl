# sourceware.org/elfutils — libelf and libdw (and libasm), the ELF and DWARF
# libraries, with the eu-* programs. Batch 3 of go-zpkg/recipes#348 (design
# go-zpkg/packages#440): systemd's `elfutils` option (meson_options.txt:474)
# lets systemd-coredump put a stack trace in the journal (dwfl) and parses
# ELF notes in `systemd-coredump` and package metadata; it needs libdw and libelf.
#
# ⛔ WRITTEN FROM ELFUTILS'S OWN FILES (configure.ac, m4/zip.m4, the headers) at
# 0.197, the newest release: the FTP listing has directories 0.190 to 0.197, and
# `git ls-remote --tags` of sourceware's git lists elfutils-0.197 after
# elfutils-0.196 (the `dts-*` tags there are a different series).
# ⛔ NOT BUILT. Builds are suspended by a security hold; what is established is
# the inputs, each traced to a line in the project's own files.
#
# WHAT IS ON. libelf, libdw, libasm and the eu-* programs. The four compression
# libraries of libdwfl are STATED (configure.ac:478-502, m4/zip.m4:5-20): zlib is
# required (:479), bzlib, lzma and zstd default to a probe that silently follows
# whatever is on the link path, so each is `--with-` and declared. libzstd >= 1.4.0
# is also asked of pkg-config (:508-513).
# WHAT IS OFF, with the reason:
#   libdebuginfod and the debuginfod server (:987-1056): they need libcurl and
#       json-c (:931-932, :996-1002) and, for the server, libmicrohttpd, sqlite3
#       and libarchive (:1003-1033), each probed on the host. systemd needs
#       neither. OFF, as are IMA verification (:989, :1035-1048, librpm and
#       imaevm.h) and --without-libarchive (:1008-1020).
#   eu-stackprof (:935-980) is `auto`: it needs json-c and C++20 <format>. OFF.
#   --disable-nls (:808, AM_GNU_GETTEXT external, `--disable-nls` at configure
#       :1662): gettext would otherwise be taken from the host.
#   --disable-demangler (:556-567): the default is ON and ERRORS when
#       __cxa_demangle is not in libstdc++; the demangler only serves eu-nm and
#       eu-addr2line output, which systemd does not use.
#   --disable-valgrind, helgrind, sanitizers, gprof, gcov, debugpred: defaults off
#       (:161, :314-333, :349-397), left at their defaults.
# C LIBRARY. elfutils needs argp, fts and obstack: glibc has them (:733-753 are
# AC_SEARCH_LIBS fall-backs to libargp, libfts and libobstack that no recipe
# provides), so the build is for glibc; musl would need those three libraries.

summary = "elfutils: libelf and libdw (ELF and DWARF libraries) with the eu-* programs"

# libelf/libelf.h and libdw/libdw.h (lines 6-19): "either the GNU Lesser General
# Public License ... version 3 ... or the GNU General Public License ... version 2,
# or both in parallel". src/readelf.c:7-8: the programs are GPL version 3 or later.
license = "(GPL-2.0-or-later OR LGPL-3.0-or-later) AND GPL-3.0-or-later"

platforms = ["linux"]

versions {
  # The FTP area has one directory per release (`0.197/`, listing read at
  # https://sourceware.org/elfutils/ftp/). There is no GitHub repository
  # (`git ls-remote https://github.com/elfutils/elfutils.git`: not found).
  url   = "https://sourceware.org/elfutils/ftp/"
  # Unanchored: the anchored form `^\d+\.\d+/?$` matched NOTHING in CI (the
  # resolver does not hand it the bare link text); this form resolves 0.197.
  match = "/\\d+\\.\\d+\\//"
  strip = ["/\\/$/"]
}

dependencies = {
  "zlib.net"             = "*"
  "sourceware.org/bzip2" = "*"
  "tukaani.org/xz"       = "*"
  "facebook.com/zstd"    = "*"
}

distributable {
  # The SIGNED release tarball (elfutils-0.197.tar.bz2.sig beside it) from
  # sourceware.org: it carries the generated configure.
  url              = "https://sourceware.org/elfutils/ftp/{{version.raw}}/elfutils-{{version.raw}}.tar.bz2"
  strip-components = 1

  # 0.197: 12225442 bytes. Recorded with `zpkb sourcepin --sig auto` (signature
  # verified, see provenance.note).
  sha256 = {
    "0.197" = "1fdf525f22dcf796d99a99ba3ea00a1f7b1ae5421bc62e8443a708920b99b904"
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

      # :478-502 the compression libraries of libdwfl, stated.
      "--with-zlib",
      "--with-bzlib",
      "--with-lzma",
      "--with-zstd",

      "--disable-libdebuginfod",
      "--disable-debuginfod",
      "--disable-debuginfod-ima-verification",
      "--without-libarchive",
      "--disable-stackprof",
      "--disable-nls",
      "--disable-demangler",

      # configure:1663 and :1634: elfutils' own rpath handling is the gettext
      # macro's, off here (the rpaths are set explicitly below); deterministic
      # archives are the upstream default (:63-72) and stated.
      "--disable-rpath",
      "--enable-deterministic-archives",

      # configure:1673 a 32-bit time_t switch, named so it is on everywhere.
      "--enable-year2038",
    ]

    PKG_CONFIG_PATH = "{{deps.zlib.net.prefix}}/lib/pkgconfig:{{deps.tukaani.org/xz.prefix}}/lib/pkgconfig:{{deps.facebook.com/zstd.prefix}}/lib/pkgconfig"

    # eu_ZIPLIB (m4/zip.m4:10) probes with AC_SEARCH_LIBS, found through -L; the
    # BZ2 library has no .pc (configure.ac:487). Each directory is also a
    # run-time rpath (libdw links them).
    LDFLAGS = "-L{{deps.zlib.net.prefix}}/lib -L{{deps.sourceware.org/bzip2.prefix}}/lib -L{{deps.tukaani.org/xz.prefix}}/lib -L{{deps.facebook.com/zstd.prefix}}/lib -Wl,-rpath,{{prefix}}/lib -Wl,-rpath,{{deps.zlib.net.prefix}}/lib -Wl,-rpath,{{deps.sourceware.org/bzip2.prefix}}/lib -Wl,-rpath,{{deps.tukaani.org/xz.prefix}}/lib -Wl,-rpath,{{deps.facebook.com/zstd.prefix}}/lib"
    CPPFLAGS = "-I{{deps.zlib.net.prefix}}/include -I{{deps.sourceware.org/bzip2.prefix}}/include -I{{deps.tukaani.org/xz.prefix}}/include -I{{deps.facebook.com/zstd.prefix}}/include"
  }

  script = [
    "./configure $ARGS",
    "make --jobs {{ hw.concurrency }}",
    "make install",
  ]
}

provides = [
  "bin/eu-readelf",
  "bin/eu-nm",
  "bin/eu-addr2line",
]

test {
  script = [
    "test -x \"{{prefix}}/bin/eu-readelf\"",
    "test -f \"{{prefix}}/include/libelf.h\"",
    "test -f \"{{prefix}}/include/elfutils/libdwfl.h\"",
    "test -f \"{{prefix}}/lib/pkgconfig/libelf.pc\"",
    "test -f \"{{prefix}}/lib/pkgconfig/libdw.pc\"",
    "grep -q '^Version: {{version.raw}}' \"{{prefix}}/lib/pkgconfig/libdw.pc\"",
    "test -e \"{{prefix}}/lib/libelf.so\"",
    "test -e \"{{prefix}}/lib/libdw.so\"",
    "\"{{prefix}}/bin/eu-readelf\" --version | grep -F '{{version.raw}}'",
  ]
}

provenance {
  read = [
    "configure.ac",        # :478-502 compression libraries; :508-513 zstd compress; :556-567 demangler; :808 gettext; :931-980 curl, json-c, stackprof; :987-1074 debuginfod, libarchive, ima
    "m4/zip.m4",           # :5-20 the --with-X probe and its `default` state
    "libdw/libdw.h",       # :6-19 the dual licence of the libraries
    "src/readelf.c",       # :7-8 the programs are GPL-3.0-or-later
    "https://sourceware.org/elfutils/ftp/ (the release directory listing)",
  ]

  consulted = []

  note = <<EOT
  signature  https://sourceware.org/elfutils/ftp/0.197/elfutils-0.197.tar.bz2.sig
  signer     6C2B631563B8D330578D3CB474FD3FA2779E7073 (RSA 2048, created
             2024-02-26), signed 2026-10-19T23:57:22Z
  identity   Aaron Merey <amerey@redhat.com>
  key from   keyserver.ubuntu.com, verified by `zpkb sourcepin --sig auto --key
             <file> --fingerprint 6C2B6315…7073` against that file.

⚠ THE FINGERPRINT IS NOT NAMED BY THE PROJECT. The signature's own issuer
fingerprint was used; the trust rests on the key carrying the user ID of an
elfutils maintainer (Red Hat) as the keyserver holds it, NOT on a key the
project publishes. The source URL is the project's own FTP, not the GitHub tag
archive.

⛔ NOT BUILT. The `versions` block is verified: `zpkb lint --check-newest-pinned`
resolves 0.197 from the FTP listing. Unverified: that
`--enable-deterministic-archives` and `--disable-rpath` are accepted verbatim
(read from configure's help text, not run); that the headers land in
include/elfutils for libdw (libdwfl.h, read from the Makefile.am layout and not
checked); and that no unlisted host library (a lone libzstd.pc found first)
shadows the declared prefix.
EOT
}
