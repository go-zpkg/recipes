# github.com/libarchive/libarchive — libarchive and the bsdtar, bsdcpio, bsdcat
# and bsdunzip tools: reading and writing tar, cpio, zip, 7zip, xar, mtree, ar,
# iso9660 and the compression filters. Batch 2 of go-zpkg/recipes#348 (design
# go-zpkg/packages#440): systemd's `libarchive` option (meson_options.txt:496)
# serves importd's tar import and sysext/portable images from archives.
#
# ⛔ WRITTEN FROM LIBARCHIVE'S OWN FILES (configure.ac, COPYING) read at 3.8.9;
# the pin is the newest tag, 3.8.11 (`git ls-remote --tags` lists v3.8.11 above
# v3.8.10 and v3.8.9, no v3.9 or v4 tag exists). The 3.8.9 to 3.8.11 changes
# were not re-read.
# ⛔ NOT BUILT. Builds are suspended by a security hold; what is established is
# the inputs, each traced to a line in libarchive's own files.

summary = "libarchive: multi-format archive and compression library, with bsdtar, bsdcpio and bsdcat"

# COPYING:1-30 lists the exceptions (3-clause UC Regents files, one public-domain
# file, the BLAKE2 files triple-licensed CC0-1.0 / OpenSSL / Apache-2.0); the
# notice at the bottom of the file is the 2-clause BSD licence that covers the rest.
license = "BSD-2-Clause"

versions {
  # Tags are `v3.8.9`.
  github = "libarchive/libarchive"
}

distributable {
  # The SIGNED release tarball (with .tar.xz.asc beside it): it carries the
  # generated configure that the GitHub tag archive does not.
  url              = "https://github.com/libarchive/libarchive/releases/download/v{{version.raw}}/libarchive-{{version.raw}}.tar.xz"
  strip-components = 1

  # 3.8.11: 6754236 bytes. Recorded with `zpkb sourcepin --sig auto` (signature
  # verified, see provenance.note).
  sha256 = {
    "3.8.11" = "a3dc0872b1b39da34dc18ef1b944f0f11ffd37425d70ae04be679279f1cf43d2"
  }
}

dependencies = {
  "zlib.net"                   = "*"
  "sourceware.org/bzip2"       = "*"
  "tukaani.org/xz"             = "*"
  "lz4.org"                    = "*"
  "facebook.com/zstd"          = "*"
  "openssl.org"                = "^3"
  "gnome.org/libxml2"          = "^2.15"
  "savannah.nongnu.org/acl"    = "*"
  "savannah.nongnu.org/attr"   = "*"
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

      # Every `--with-X` library of configure.ac is a PROBE that silently links
      # whatever the builder has, so each is stated.
      # zlib (:390), bz2lib (:414), lzma (:506), lz4 (:486), zstd (:494): default
      # ON, found through the include and library paths below; stated.
      "--with-zlib",
      "--with-bz2lib",
      "--with-lzma",
      "--with-lz4",
      "--with-zstd",

      # :554 openssl for the mtree and xar hashes, default ON; stated.
      "--with-openssl",

      # :560 libxml2 for xar, default ON, found as `libxml-2.0` (:567).
      "--with-xml2",

      # :562 expat is only the fall-back when libxml2's headers are absent
      # (:576-581); libxml2 is declared, so OFF (and no host expat is probed).
      "--without-expat",

      # :446-458 libb2: without it the bundled BLAKE2 sources are compiled
      # (AM_CONDITIONAL INC_BLAKE2); there is no libb2 recipe. OFF.
      "--without-libb2",

      # :539-545 lzo2 is `--with-lzo2` only (default OFF), mbedtls (:550) and
      # nettle (:552) likewise; no recipe, left OFF. cng (:547) is Windows.

      # :460 iconv: the C library provides it on glibc (AM_ICONV); default.

      # :920 xattr and :1023 acl: default ON when found; libacl and libattr are
      # declared, stated so a missing header is an error here, not a silent drop.
      "--enable-xattr",
      "--enable-acl",

      # :583-591 the POSIX regex library: auto picks libc's regcomp (:594-599)
      # before any pcre; stated so that no host pcre can be chosen.
      "--enable-posix-regex-lib=libc",

      # :134, :222, :178, :296 the four tools, default ON; stated.
      "--enable-bsdtar",
      "--enable-bsdcpio",
      "--enable-bsdcat",
      "--enable-bsdunzip",

      # The consumers (systemd's importd) link the shared library.
      "--disable-static",
    ]

    PKG_CONFIG_PATH = "{{deps.openssl.org.prefix}}/lib/pkgconfig:{{deps.openssl.org.prefix}}/lib64/pkgconfig:{{deps.zlib.net.prefix}}/lib/pkgconfig:{{deps.sourceware.org/bzip2.prefix}}/lib/pkgconfig:{{deps.tukaani.org/xz.prefix}}/lib/pkgconfig:{{deps.lz4.org.prefix}}/lib/pkgconfig:{{deps.facebook.com/zstd.prefix}}/lib/pkgconfig:{{deps.gnome.org/libxml2.prefix}}/lib/pkgconfig:{{deps.savannah.nongnu.org/acl.prefix}}/lib/pkgconfig:{{deps.savannah.nongnu.org/attr.prefix}}/lib/pkgconfig"

    # configure.ac:395, :439, :491, :499 probe zlib, bz2, lz4 and zstd with
    # AC_CHECK_LIB / a link test, and :1029 libacl: found through -L, and each
    # directory is also a run-time rpath.
    LDFLAGS = "-L{{deps.zlib.net.prefix}}/lib -L{{deps.sourceware.org/bzip2.prefix}}/lib -L{{deps.lz4.org.prefix}}/lib -L{{deps.facebook.com/zstd.prefix}}/lib -L{{deps.savannah.nongnu.org/acl.prefix}}/lib -L{{deps.savannah.nongnu.org/attr.prefix}}/lib -L{{deps.openssl.org.prefix}}/lib -L{{deps.openssl.org.prefix}}/lib64 -Wl,-rpath,{{prefix}}/lib -Wl,-rpath,{{deps.zlib.net.prefix}}/lib -Wl,-rpath,{{deps.sourceware.org/bzip2.prefix}}/lib -Wl,-rpath,{{deps.tukaani.org/xz.prefix}}/lib -Wl,-rpath,{{deps.lz4.org.prefix}}/lib -Wl,-rpath,{{deps.facebook.com/zstd.prefix}}/lib -Wl,-rpath,{{deps.openssl.org.prefix}}/lib -Wl,-rpath,{{deps.openssl.org.prefix}}/lib64 -Wl,-rpath,{{deps.gnome.org/libxml2.prefix}}/lib -Wl,-rpath,{{deps.savannah.nongnu.org/acl.prefix}}/lib -Wl,-rpath,{{deps.savannah.nongnu.org/attr.prefix}}/lib"

    # The headers (bzlib.h :418, lz4.h :490, zstd.h :498, acl and xattr headers)
    # are found through the include path.
    CPPFLAGS = "-I{{deps.zlib.net.prefix}}/include -I{{deps.sourceware.org/bzip2.prefix}}/include -I{{deps.lz4.org.prefix}}/include -I{{deps.facebook.com/zstd.prefix}}/include -I{{deps.savannah.nongnu.org/acl.prefix}}/include -I{{deps.savannah.nongnu.org/attr.prefix}}/include -I{{deps.openssl.org.prefix}}/include"
  }

  script = [
    "./configure $ARGS",
    "make --jobs {{ hw.concurrency }}",
    "make install",
  ]
}

provides = [
  "bin/bsdtar",
  "bin/bsdcpio",
  "bin/bsdcat",
  "bin/bsdunzip",
]

test {
  script = [
    "test -x \"{{prefix}}/bin/bsdtar\"",
    "test -x \"{{prefix}}/bin/bsdcpio\"",
    "test -x \"{{prefix}}/bin/bsdcat\"",
    "test -f \"{{prefix}}/include/archive.h\"",
    "test -f \"{{prefix}}/include/archive_entry.h\"",
    "test -f \"{{prefix}}/lib/pkgconfig/libarchive.pc\"",
    # Prints its version and the libraries it linked, touching nothing.
    "\"{{prefix}}/bin/bsdtar\" --version | grep -F 'libarchive {{version.raw}}'",
  ]
}

provenance {
  read = [
    "configure.ac",  # :134-334 the four tools; :390-581 zlib, bz2, libb2, iconv, lz4, zstd, lzma, lzo2, mbedtls, nettle, openssl, xml2, expat; :583-650 regex library; :920-1050 xattr and acl; :1320-1389 crypto
    "COPYING",       # :1-30 the exceptions; the bottom notice is 2-clause BSD
    "https://github.com/libarchive/libarchive (git ls-remote --tags)",
    "https://www.libarchive.org/",
  ]

  consulted = []

  note = <<EOT
  signature  https://github.com/libarchive/libarchive/releases/download/v3.8.11/libarchive-3.8.11.tar.xz.asc
  signer     659C84C0E23EA1FA97E0B58CC040B508D63D2B36 (RSA 4096, expires
             2029-11-17), signed 2026-10-30T21:28:16Z
  identity   Martin Matuska <martin@matuska.de> (also <mm@FreeBSD.org>)
  key from   keyserver.ubuntu.com, verified by `zpkb sourcepin --sig auto --key
             <file> --fingerprint 659C84C0…2B36` against that file.

⚠ THE FINGERPRINT IS NOT NAMED BY THE PROJECT. Neither the release tarball, the
README (v3.8.9) nor www.libarchive.org was found to state a signing key, so
the fingerprint is the signature's own issuer fingerprint, and the trust placed
in it rests on the key carrying the user ID of Martin Matuska, who makes
libarchive's releases. That is evidence of "the maintainer's key as the
keyserver holds it", NOT of "the key the project publishes". The same digest
is pinned either way; a second witness would be a project-published key.

⛔ NOT BUILT. Unverified: that the shipped configure accepts exactly the
`--with-*` / `--enable-*` spellings above (read at configure.ac, not run);
that libxml2's `libxml-2.0.pc` is found (:567) and that every dependency
prefix's lib directory is the one named in LDFLAGS (lib64 is listed for openssl
only); and that `--enable-posix-regex-lib=libc` is accepted verbatim (:586).
EOT
}
