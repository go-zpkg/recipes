# github.com/SELinuxProject/libsepol — libsepol, the SELinux binary policy
# library, which libselinux (github.com/SELinuxProject/libselinux) links as a
# static archive. Step of go-zpkg/recipes#348 (design go-zpkg/packages#440):
# systemd's `selinux` option (meson.build:1122-1124
# `dependency('libselinux', version : '>= 2.1.9')`) needs libselinux, which
# needs this.
#
# ⛔ WRITTEN FROM libsepol's OWN Makefiles, at 3.11 — the newest release
# (github.com/SELinuxProject/selinux/releases/tag/3.11, 2026-07-01).
# ⛔ NOT BUILT. Builds are suspended by a security hold; what is established is
# the inputs, each traced to a line in libsepol's own files.
#
# HOW IT BUILDS (Makefile, src/Makefile, include/Makefile; no configure step):
#   PREFIX is a variable of all three; src/Makefile:4 LIBDIR defaults to
#       $(PREFIX)/lib and :5 SHLIBDIR to the ABSOLUTE `/lib`: the shared
#       library would be installed OUTSIDE the prefix, so SHLIBDIR is pinned
#       to {{prefix}}/lib (and :100 links libsepol.so to it with `ln --relative`).
#   Only `include` and `src` are built and installed. The top-level Makefile
#       also builds `utils` and `man`: the utilities are not what libselinux
#       needs, and installing them would add binaries to a library recipe.
#   CIL is kept (src/Makefile:26 `DISABLE_CIL` is not set), because
#       include/Makefile:14 installs the cil headers unconditionally from CILDIR
#       and libsepol 3.x exports CIL to its consumers. CIL's lexer is generated:
#       the tarball ships cil/src/cil_lexer.l and not the .c, and src/Makefile:12
#       is `LEX = flex` (:82 `$(LEX) -o $@ $<`): flex is a build dependency.

summary = "libsepol: SELinux binary policy library"

# LICENSE (the file) is the text of the LGPL version 2.1. The "or later" is the
# project's usual per-file header, NOT read here (see provenance.note).
license = "LGPL-2.1-or-later"

platforms = ["linux"]

versions {
  # Tags of the one SELinuxProject/selinux repository are `3.11`; the
  # libsepol and libselinux assets share the version.
  github = "SELinuxProject/selinux"
}

distributable {
  url              = "https://github.com/SELinuxProject/selinux/releases/download/{{version.raw}}/libsepol-{{version.raw}}.tar.gz"
  strip-components = 1

  # 3.11: `zpkb sourcepin -sig auto` verified the detached signature, see
  # provenance.note.
  sha256 = {
    "3.11" = "79f3d2c88f44b7eb5cf54d9792e03232297e17f97a179163f2750099a00f164d"
  }
}

build {
  dependencies = {
    "gnu.org/make"           = "*"
    "gnu.org/gcc"            = "*"
    "github.com/westes/flex" = "*"
  }

  script = [
    "make -C include PREFIX={{prefix}} install",
    "make -C src PREFIX={{prefix}} LIBDIR={{prefix}}/lib SHLIBDIR={{prefix}}/lib --jobs {{ hw.concurrency }}",
    "make -C src PREFIX={{prefix}} LIBDIR={{prefix}}/lib SHLIBDIR={{prefix}}/lib install",
  ]
}

test {
  script = [
    "test -f \"{{prefix}}/include/sepol/policydb.h\"",
    "test -f \"{{prefix}}/include/sepol/cil/cil.h\"",
    "test -f \"{{prefix}}/lib/libsepol.a\"",
    "test -f \"{{prefix}}/lib/libsepol.so.2\"",
    "test -f \"{{prefix}}/lib/pkgconfig/libsepol.pc\"",
    "grep -q '^Version: {{version.raw}}' \"{{prefix}}/lib/pkgconfig/libsepol.pc\"",
  ]
}

provenance {
  read = [
    "Makefile",          # the top-level targets: why `make -C include` and `make -C src` are run instead
    "src/Makefile",      # :4-5 LIBDIR, SHLIBDIR; :12 LEX = flex; :26 DISABLE_CIL; :65 libsepol.pc; :82 flex; :93-100 install
    "LICENSE",           # the LGPL 2.1 text
    "include/Makefile",  # :2 PREFIX; :12-14 headers incl. the cil headers
    "https://github.com/SELinuxProject/selinux/releases/tag/3.11",
  ]

  consulted = []

  note = <<EOT
  source     https://github.com/SELinuxProject/selinux/releases/download/3.11/libsepol-3.11.tar.gz
  sha256     79f3d2c88f44b7eb5cf54d9792e03232297e17f97a179163f2750099a00f164d
  signature  https://github.com/SELinuxProject/selinux/releases/download/3.11/libsepol-3.11.tar.gz.asc
  signer     68D21823342A13683AEB3E4EFB4C685B5DC1C13E, Petr Lautrbach
             <lautrbach@redhat.com>, signed 2026-07-01 by the subkey
             7200EB2C3F5E488463C0CE9ECDCAE8C927C6BE31
  key from   keyserver.ubuntu.com, verified by `zpkb sourcepin --sig auto`.

⚠ THE FINGERPRINT IS NOT NAMED BY THE PROJECT. The signature's own issuer
fingerprint was used; trust rests on the key carrying the maintainer's user ID
as the keyserver holds it. The key expired 2026-11-04, AFTER the signature
(2026-07-01), and sourcepin judges expiry at the signing instant.

⛔ NOT BUILT. Unverified: that the per-file headers say "or later" (only the
LICENSE file, the LGPL 2.1 text, was read; no source header); that flex is findable on the build PATH; that
`ln -sf --relative` (src/Makefile:100) is available in the tree's coreutils;
that src/Makefile's own CFLAGS (-Werror) hold with this tree's gcc.
EOT
}
