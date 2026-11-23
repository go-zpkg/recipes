# skarnet.org/skalibs — the C library every skarnet.org program is built on
# (libskarnet: buffers, stralloc, sockets, byte and string handling, a
# non-glibc `getopt`, time, environment and process helpers).
#
# First of the nine skarnet.org recipes that make s6 an init system and process
# supervision suite in this pantry: skalibs, execline, s6, s6-rc,
# s6-linux-init, s6-portable-utils, s6-linux-utils, mdevd, utmps.
#
# ⛔ WRITTEN FROM THE PROJECT'S OWN FILES (INSTALL, configure) at 2.16.0.0, the
# newest release on https://skarnet.org/software/skalibs/ (the GitHub mirror's
# newest tag, v2.16.0.0, agrees). The tarball was fetched and built here; the
# digest below is computed from that download and is not copied from anywhere.
#
# THE CONFIGURE SCRIPT IS NOT AUTOCONF: it is skarnet's own shell script and it
# accepts only the options `./configure --help` prints. Read from that output:
#   --enable-pkgconfig  builds and installs libskarnet.pc (off by default).
#   --prefix            lib, include and sysdeps all follow it.
#   shared libraries and static libraries are BOTH built by default, with PIC
#   static libraries and an RPATH in the shared ones. Left at the defaults: the
#   dependents link the static archive (their own default, `allstatic`), so no
#   run-time library lookup is needed for any of them.
# The sysdeps directory (PREFIX/lib/skalibs/sysdeps) is a build-time input of
# every dependent, read by their `--with-sysdeps`; it is installed, not removed.

summary = "skalibs: the C library underneath every skarnet.org program"

# COPYING: ISC licence.
license = "ISC"

versions {
  # Tags are `v2.16.0.0`; four numeric components.
  github = "skarnet/skalibs"
}

distributable {
  # The release tarball on the author's own site; the GitHub repository is a
  # mirror that publishes no release assets.
  url              = "https://skarnet.org/software/skalibs/skalibs-{{version.raw}}.tar.gz"
  strip-components = 1

  # 2.16.0.0: 269049 bytes, computed from the download.
  sha256 = {
    "2.16.0.0" = "90a3deda94a40d7d6a4495fe6feaf91c0185e0428d59cbd150a1a468741269aa"
  }
}

build {
  dependencies = {
    "gnu.org/make" = "*"
    "gnu.org/gcc"  = "*"
  }

  env = {
    ARGS = [
      "--prefix={{prefix}}",
      "--enable-pkgconfig",
    ]
  }

  script = [
    "./configure $ARGS",
    "make --jobs {{hw.concurrency}}",
    "make install",
  ]
}

test {
  dependencies = {
    "gnu.org/gcc" = "*"
  }

  script = [
    "test -f {{prefix}}/include/skalibs/stralloc.h",
    "test -f {{prefix}}/lib/libskarnet.a",
    "test -d {{prefix}}/lib/skalibs/sysdeps",
    "test -f {{prefix}}/lib/pkgconfig/libskarnet.pc",
    # A program linked against the LIBRARY: stralloc builds a string, buffer
    # writes it. The binary is run, not only linked.
    {
      fixture = {
        content  = <<EOT
#include <string.h>
#include <skalibs/stralloc.h>
#include <skalibs/buffer.h>

int main(void) {
  stralloc sa = STRALLOC_ZERO;
  if (!stralloc_catb(&sa, "skalibs ", 8)) return 1;
  if (!stralloc_catb(&sa, "works\n", 6)) return 1;
  if (sa.len != 14 || memcmp(sa.s, "skalibs works\n", 14)) return 2;
  if (buffer_putflush(buffer_1, sa.s, sa.len) < 0) return 3;
  stralloc_free(&sa);
  return 0;
}
EOT
        extname = "c"
      }
      run = "gcc $FIXTURE -o skalibs-test -I{{prefix}}/include -L{{prefix}}/lib -Wl,-rpath,{{prefix}}/lib -lskarnet"
    },
    "./skalibs-test",
  ]
}

provenance {
  read = [
    "INSTALL",         # requirements; `./configure && make && sudo make install`
    "configure",       # the option list printed by --help
    "COPYING",         # ISC
    "https://skarnet.org/software/skalibs/",
  ]

  consulted = []

  note = <<EOT
Built and run here on macOS (arm64) and on Linux with the commands of this file,
the install prefix a directory of its own: the library, the headers, the pkg-config
file and the sysdeps directory landed under it and the test program ran.

⚠ No upstream signature or checksum file is published beside the tarball (the
directory listing holds only the .tar.gz files), so the digest is the one
computed from the download, and a second witness is not available.
EOT
}
