# github.com/SELinuxProject/libselinux — libselinux, the SELinux userspace
# library. Step of go-zpkg/recipes#348 (design go-zpkg/packages#440): systemd's
# `selinux` option (meson.build:1122-1124
# `dependency('libselinux', version : '>= 2.1.9')`, option at
# meson_options.txt:407) links it.
#
# ⛔ WRITTEN FROM libselinux's OWN Makefiles and LICENSE, at 3.11 — the newest
# release (github.com/SELinuxProject/selinux/releases/tag/3.11, 2026-07-01).
# ⛔ NOT BUILT. Builds are suspended by a security hold; what is established is
# the inputs, each traced to a line in libselinux's own files.
#
# HOW IT BUILDS (Makefile, src/Makefile; no configure step):
#   The top-level Makefile computes PCRE_MODULE, PCRE_CFLAGS and PCRE_LDLIBS
#       (:26-35, USE_PCRE2 defaults y: libpcre2-8 through pkg-config) and
#       EXPORTS them to the sub-makes. Running `make -C src` alone would lose
#       them, so the build goes through the top-level Makefile, with
#       SUBDIRS="include src" (:1) overridden on the command line: `utils` and
#       `man` (the SELinux command-line tools and man pages) are not built.
#   src/Makefile:16 SHLIBDIR defaults to the ABSOLUTE `/lib`, outside the
#       prefix: pinned to {{prefix}}/lib, as LIBDIR (:15) is.
#   libsepol: src/Makefile:57-59 defines LDLIBS_LIBSEPOLA (`-l:libsepol.a`)
#       but the shared link (:168-169) does not use it; what the library
#       carries is libselinux.pc's `Requires.private: libsepol @PCRE_MODULE@`
#       (src/libselinux.pc.in:10). So libsepol is a dependency because every
#       consumer's pkg-config resolves it (systemd's meson `dependency()`
#       asks for libselinux.pc), and LDFLAGS/CPPFLAGS name its directories in
#       case a file needs them.
#   The Python and Ruby wrappers (pywrap, rubywrap, :153-162) are separate
#       targets that `all` does not build.
#   src/Makefile:78 default CFLAGS (carries -Werror) is left alone: only
#       CPPFLAGS and LDFLAGS are set.

summary = "libselinux: SELinux userspace library"

# LICENSE (the file) says "This library (libselinux) is public domain
# software, i.e. not copyrighted", with an NSA warranty exclusion: no SPDX
# identifier names that, so it is a LicenseRef.
license = "LicenseRef-libselinux-public-domain"

platforms = ["linux"]

versions {
  # Tags of the one SELinuxProject/selinux repository are `3.11`; the
  # libsepol and libselinux assets share the version.
  github = "SELinuxProject/selinux"
}

dependencies = {
  "pcre.org/v2"                        = "^10"
  "github.com/SELinuxProject/libsepol" = "*"
}

distributable {
  url              = "https://github.com/SELinuxProject/selinux/releases/download/{{version.raw}}/libselinux-{{version.raw}}.tar.gz"
  strip-components = 1

  # 3.11: `zpkb sourcepin -sig auto` verified the detached signature, see
  # provenance.note.
  sha256 = {
    "3.11" = "73d419c6e20e874adaa4019372cbd097eecf4d276e13f27ec5e67d35c0bd203c"
  }
}

build {
  dependencies = {
    "gnu.org/make"               = "*"
    "freedesktop.org/pkg-config" = "*"
    "gnu.org/gcc"                = "*"
  }

  env = {
    PKG_CONFIG_PATH = "{{deps.pcre.org/v2.prefix}}/lib/pkgconfig:{{deps.github.com/SELinuxProject/libsepol.prefix}}/lib/pkgconfig"
    CPPFLAGS        = "-I{{deps.github.com/SELinuxProject/libsepol.prefix}}/include"
    # src/Makefile:97 sets the SONAME and version script; :169 appends
    # $(LDFLAGS) to the shared link.
    LDFLAGS         = "-L{{deps.github.com/SELinuxProject/libsepol.prefix}}/lib -Wl,-rpath,{{prefix}}/lib -Wl,-rpath,{{deps.pcre.org/v2.prefix}}/lib"
  }

  script = [
    "make SUBDIRS=\"include src\" PREFIX={{prefix}} LIBDIR={{prefix}}/lib SHLIBDIR={{prefix}}/lib --jobs {{ hw.concurrency }}",
    "make SUBDIRS=\"include src\" PREFIX={{prefix}} LIBDIR={{prefix}}/lib SHLIBDIR={{prefix}}/lib install",
  ]
}

test {
  script = [
    "test -f \"{{prefix}}/include/selinux/selinux.h\"",
    "test -f \"{{prefix}}/lib/libselinux.a\"",
    "test -f \"{{prefix}}/lib/libselinux.so.1\"",
    "test -f \"{{prefix}}/lib/pkgconfig/libselinux.pc\"",
    "grep -q '^Version: {{version.raw}}' \"{{prefix}}/lib/pkgconfig/libselinux.pc\"",
  ]
}

provenance {
  read = [
    "Makefile",      # :1 SUBDIRS; :26-35 PCRE2 and its export; :53-56 the per-subdirectory loop
    "src/Makefile",  # :15-16 LIBDIR, SHLIBDIR; :57-59 -l:libsepol.a; :78 CFLAGS; :148-151 all; :168-170 the shared link; :187-196 install
    "LICENSE",       # :1 public domain, with the NSA warranty exclusion
    "https://github.com/SELinuxProject/selinux/releases/tag/3.11",
  ]

  consulted = []

  note = <<EOT
  source     https://github.com/SELinuxProject/selinux/releases/download/3.11/libselinux-3.11.tar.gz
  sha256     73d419c6e20e874adaa4019372cbd097eecf4d276e13f27ec5e67d35c0bd203c
  signature  https://github.com/SELinuxProject/selinux/releases/download/3.11/libselinux-3.11.tar.gz.asc
  signer     68D21823342A13683AEB3E4EFB4C685B5DC1C13E, Petr Lautrbach
             <lautrbach@redhat.com>, the same key that signed libsepol 3.11
  key from   keyserver.ubuntu.com, verified by `zpkb sourcepin --sig auto`.

⚠ THE FINGERPRINT IS NOT NAMED BY THE PROJECT. The signature's own issuer
fingerprint was used; trust rests on the key carrying the maintainer's user ID
as the keyserver holds it. The key expired 2026-11-04, AFTER the signature
(2026-07-01), and sourcepin judges expiry at the signing instant.

⛔ NOT BUILT. Unverified: that the library's sources need libsepol's headers
at all (CPPFLAGS gives the include root if so); that systemd's recipe puts
libsepol's lib/pkgconfig on PKG_CONFIG_PATH (libselinux.pc requires it); that
`make SUBDIRS="..."` passed on the command line overrides the Makefile's own
assignment (it does in GNU make) and is exported to the sub-make; that
libselinux.pc's @PCRE_MODULE@ resolves to libpcre2-8 (read :10, not run); that src/Makefile's own CFLAGS (-Werror) hold with
this tree's gcc; that libselinux 3.11 still installs libselinux.so.1 (:50
LIBVERSION = 1).
EOT
}
