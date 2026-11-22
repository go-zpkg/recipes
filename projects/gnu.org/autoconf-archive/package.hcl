# gnu.org/autoconf-archive — the GNU Autoconf Archive, a collection of more than
# 500 Autoconf macros (README:4-5), installed as m4 files into share/aclocal.
# Step of go-zpkg/recipes#348 (design go-zpkg/packages#440): libapparmor's
# configure.ac (libraries/libapparmor/configure.ac:101-103) calls
# AX_CHECK_COMPILE_FLAG and stops with "'autoconf-archive' missing" when the
# macro is not on aclocal's path, and the apparmor tag archive ships no
# generated configure, so autoreconf has to find it.
#
# ⛔ READ FROM THE RELEASE TARBALL's own configure.ac, Makefile.am, README and
# COPYING, at 2026.11.11 — the newest release on ftp.gnu.org/gnu/autoconf-archive/
# (listing read 2026-11-22).
# ⛔ NOT BUILT. Builds are suspended by a security hold.
#
# WHAT IT INSTALLS (Makefile.am):
#   :20-21  `aclocaldir = $(datadir)/aclocal`, `dist_aclocal_DATA = $(M4FILES)`:
#           every m4/*.m4 goes to {{prefix}}/share/aclocal. NO binary.
#   :17     SUBDIRS = doc: the texinfo documentation, built and installed too.
#   :19     COPYING, COPYING.EXCEPTION, README, AUTHORS to share/doc.
# configure.ac has ZERO AC_ARG_ENABLE and ZERO AC_ARG_WITH (read, :1-29): nothing
# to switch, and only AC_PROG_SED is checked.
#
# ⚠ aclocal does NOT look in this prefix by itself: it searches its OWN
# share/aclocal. A consumer that runs autoreconf must put
# {{deps.gnu.org/autoconf-archive.prefix}}/share/aclocal on ACLOCAL_PATH.

summary = "GNU Autoconf Archive: more than 500 Autoconf macros, installed for aclocal"

# README:56-59 says "either version 3 of the License, or (at your option) any
# later version" for the Archive, and the tarball carries COPYING.EXCEPTION
# (Makefile.am:19): the macros are usable in scripts under any licence. The
# exception's text and each macro's own header were NOT read.
license = "GPL-3.0-or-later"

platforms = ["linux", "darwin"]

versions {
  url   = "https://ftp.gnu.org/gnu/autoconf-archive/"
  match = "/autoconf-archive-\\d+\\.\\d+\\.\\d+\\.tar\\.xz/"
  strip = [
    "/^autoconf-archive-/",
    "/\\.tar\\.xz$/",
  ]
}

distributable {
  url              = "https://ftp.gnu.org/gnu/autoconf-archive/autoconf-archive-{{version.raw}}.tar.xz"
  strip-components = 1

  # 688488 bytes, recorded with the builder's own fetcher and a VERIFIED
  # signature (`zpkb sourcepin -sig auto`):
  #
  #   signed by 1A4F63A13A4649B632F65EE141BC28FE99089D72 (the primary key; this
  #   signature is made by it, there is no signing subkey)
  #   Peter Simons <simons@cryp.to>, signed 2026-11-11
  #   the key was fetched from keyserver.ubuntu.com
  sha256 = {
    "2026.11.11" = "2c18f15e2b3bb79e09622b27391df07d8608ce9f07fbfc7c1143fa683891ab26"
  }
}

build {
  dependencies = {
    "gnu.org/make" = "*"
  }

  env = {
    ARGS = [
      "--prefix={{prefix}}",
    ]
  }

  script = [
    "./configure $ARGS",
    "make --jobs {{ hw.concurrency }}",
    "make install",
  ]
}

test {
  script = [
    "test -f \"{{prefix}}/share/aclocal/ax_check_compile_flag.m4\"",
    "grep -q 'AC_DEFUN(\\[AX_CHECK_COMPILE_FLAG\\]' \"{{prefix}}/share/aclocal/ax_check_compile_flag.m4\"",
  ]
}

provenance {
  read = [
    "configure.ac",  # :11 AC_INIT with git-version-gen; :15 AM_INIT_AUTOMAKE; :20 AC_PROG_SED; :22-25 the m4 file lists; :28 Makefile and doc/Makefile; no AC_ARG_*
    "Makefile.am",   # :17 SUBDIRS = doc; :19 dist_doc_DATA incl. COPYING.EXCEPTION; :20-21 aclocaldir and dist_aclocal_DATA
    "README",        # :4-5 the collection; :31-35 downloads and signature; :56-59 GPL-3.0-or-later
    "COPYING",       # :1-2 the GPL version 3 text
    "ftp.gnu.org/gnu/autoconf-archive/ (listing: 2026.11.11 is the newest)",
  ]

  consulted = []

  note = <<EOT
  source     https://ftp.gnu.org/gnu/autoconf-archive/autoconf-archive-2026.11.11.tar.xz
  sha256     2c18f15e2b3bb79e09622b27391df07d8608ce9f07fbfc7c1143fa683891ab26
  signature  https://ftp.gnu.org/gnu/autoconf-archive/autoconf-archive-2026.11.11.tar.xz.sig
  signer     1A4F63A13A4649B632F65EE141BC28FE99089D72, Peter Simons
             <simons@cryp.to>, signed 2026-11-11
  key from   keyserver.ubuntu.com, verified by `zpkb sourcepin --sig auto`.

⚠ THE FINGERPRINT IS NOT NAMED BY THE PROJECT. The signature's own issuer
fingerprint was used; trust rests on the key carrying the maintainer's user ID
as the keyserver holds it. README:47 names only the short id 99089D72, which
is the tail of that fingerprint.

⛔ NOT BUILT. Unverified: that `make install` does not need makeinfo (doc/
ships generated info in the tarball, not checked); the licence of each
macro's header (m4/ax_check_compile_flag.m4:27-30 has a LICENSE block, not
read to the end). The test's `AC_DEFUN([AX_CHECK_COMPILE_FLAG]` spelling is
that file's line 39, read.
EOT
}
