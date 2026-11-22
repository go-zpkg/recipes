# github.com/fukuchi/libqrencode — libqrencode: QR Code and Micro QR Code
# encoding library. Batch 2 of go-zpkg/recipes#348 (design go-zpkg/packages#440):
# systemd's `qrencode` option (meson_options.txt:458) lets `homectl`,
# `systemd-cryptenroll` and `systemd-pcrlock` print QR codes in the terminal.
#
# ⛔ WRITTEN FROM THE PROJECT'S OWN CMakeLists.txt and COPYING, at 4.1.1 — the
# newest tag of the repository.
# ⛔ NOT BUILT. Builds are suspended by a security hold; what is established is
# the inputs, each traced to a line in the project's own files.
#
# OPTIONS (CMakeLists.txt):
#   BUILD_SHARED_LIBS (:11) defaults NO; ON, because systemd dlopens
#       libqrencode.so.4 (SOVERSION, :115).
#   WITH_TOOLS (:5) defaults YES: the `qrencode` command-line program is not
#       what systemd needs and, with PNG, would pull libpng; OFF, with
#       WITHOUT_PNG (:7) ON so that no host libpng is probed by find_package
#       (:22). Only the library and libqrencode.pc (:131-136) are installed.
#   WITH_TESTS (:6) defaults NO; stated.
#   GPROF, COVERAGE, ASAN (:8-10): instrumentation, OFF.

summary = "libqrencode: QR Code and Micro QR Code encoding library"

# COPYING is the GNU Lesser General Public License, version 2.1; the sources
# say "or any later version".
license = "LGPL-2.1-or-later"

versions {
  # Tags are `v4.1.1`.
  github = "fukuchi/libqrencode"
}

distributable {
  # The GitHub tag archive: the project publishes no signed tarball.
  url              = "https://github.com/fukuchi/libqrencode/archive/refs/tags/v{{version.raw}}.tar.gz"
  strip-components = 1

  # 4.1.1: 190419 bytes, `shasum -a 256` of the downloaded archive; see
  # provenance.note for why this is a cross-check and not a signature.
  sha256 = {
    "4.1.1" = "5385bc1b8c2f20f3b91d258bf8ccc8cf62023935df2d2676b5b67049f31a049c"
  }
}

build {
  dependencies = {
    "cmake.org"    = "^3"
    "gnu.org/make" = "*"
    "gnu.org/gcc"  = "*"
  }

  env = {
    ARGS = [
      "-DCMAKE_INSTALL_PREFIX={{prefix}}",
      "-DCMAKE_BUILD_TYPE=Release",

      # CMakeLists.txt:123 GNUInstallDirs may choose lib64; pinned to lib so the
      # .pc file (:131) and the rpath agree.
      "-DCMAKE_INSTALL_LIBDIR=lib",
      "-DBUILD_SHARED_LIBS=ON",
      "-DWITH_TOOLS=OFF",
      "-DWITH_TESTS=OFF",
      "-DWITHOUT_PNG=ON",
      "-DCMAKE_INSTALL_RPATH={{prefix}}/lib",
    ]
  }

  script = [
    "cmake -S . -B build $ARGS",
    "cmake --build build --parallel {{ hw.concurrency }}",
    "cmake --install build",
  ]
}

test {
  script = [
    "test -f \"{{prefix}}/include/qrencode.h\"",
    "test -f \"{{prefix}}/lib/pkgconfig/libqrencode.pc\"",
    "test -e \"{{prefix}}/lib/libqrencode.so\" || test -e \"{{prefix}}/lib/libqrencode.dylib\"",
  ]
}

provenance {
  read = [
    "CMakeLists.txt",  # :5-11 options; :22-23 find_package; :110-136 library and install; :138-157 tools
    "COPYING",         # :1-2 LGPL 2.1
    "https://github.com/fukuchi/libqrencode (git ls-remote --tags)",
  ]

  consulted = []

  note = <<EOT
  source     https://github.com/fukuchi/libqrencode/archive/refs/tags/v4.1.1.tar.gz
  sha256     5385bc1b8c2f20f3b91d258bf8ccc8cf62023935df2d2676b5b67049f31a049c

⚠ NO SIGNATURE. The project publishes no detached signature and no signed tag
that was checked; the digest is the one this recipe's author computed on the
GitHub tag archive, not a project-published checksum. GitHub regenerates tag
archives from the tag's commit, so a digest mismatch means a changed archive
or a moved tag, to be investigated and not re-pinned blindly.

⛔ NOT BUILT. Unverified: that CMake picks `-DCMAKE_INSTALL_RPATH` and
`BUILD_SHARED_LIBS` as above on every platform; that the install produces
libqrencode.so.4 with SOVERSION 4 (CMakeLists.txt:115, read, not run).
EOT
}
