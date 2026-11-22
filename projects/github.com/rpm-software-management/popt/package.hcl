# github.com/rpm-software-management/popt — the command line option parsing
# library cryptsetup's tools link (configure.ac:179 of cryptsetup: "You need
# popt 1.7 or newer to compile"). Step 3 of go-zpkg/recipes#348 (design
# go-zpkg/packages#440): lvm2 (device-mapper) -> popt -> cryptsetup.
#
# ⛔ WRITTEN FROM POPT'S OWN FILES, at 1.19 — the newest release: the project's
# release page lists popt-1.19-release above popt-1.18-release, and the
# release directory http://ftp.rpm.org/popt/releases/popt-1.x/ holds
# popt-1.18.tar.gz and popt-1.19.tar.gz and nothing newer.
# ⛔ NOT BUILT. Builds are suspended by a security hold; what is established
# is the inputs, each traced to a line in popt's own files.

summary = "popt: command line option parsing library"

# COPYING: the X11-style (MIT) licence; popt has carried it since its
# Red Hat origin. Stated, not re-read here: see provenance.note.
license = "MIT"

versions {
  # Tags are `popt-1.19-release`.
  github = "rpm-software-management/popt"
  strip = [
    "/^popt-/",
    "/-release$/",
  ]
}

distributable {
  # The release tarball, which ships the generated configure that the GitHub
  # tag archive does not. ftp.rpm.org serves its release directory over plain
  # HTTP only: its TLS certificate names another host (curl: "no alternative
  # certificate subject name matches target host name"). The digest below is
  # what makes the transport safe, and it was cross-checked (provenance.note).
  url              = "http://ftp.rpm.org/popt/releases/popt-1.x/popt-{{version.raw}}.tar.gz"
  strip-components = 1

  # 1.19: 596676 bytes. Recorded with `zpkb sourcepin` (NO signature: the
  # project publishes none, see provenance.note) and confirmed by an
  # independent `shasum -a 256` of the same file.
  sha256 = {
    "1.19" = "c25a4838fc8e4c1c8aacb8bd620edb3084a3d63bf8987fdad3ca2758c63240f9"
  }
}

build {
  dependencies = {
    "gnu.org/make" = "*"
  }

  env = {
    ARGS = [
      "--prefix={{prefix}}",

      # configure:1481 `--disable-nls` (the gettext macro AM_GNU_GETTEXT,
      # configure.ac:57, "external"): without it configure looks for the
      # host's libintl and msgfmt, a host-dependent choice. OFF.
      "--disable-nls",

      # configure:1472 `--enable-static` defaults to yes; the consumers link
      # the shared library, so the archive is not built.
      "--disable-static",
    ]
  }

  script = [
    "./configure $ARGS",
    "make --jobs {{ hw.concurrency }}",
    "make install",
  ]
}

# Makefile.am installs libpopt, popt.h and popt.pc (configure.ac:70 lists
# popt.pc.in among the generated files); popt is a library and installs no
# program.

test {
  script = [
    "test -f \"{{prefix}}/include/popt.h\"",
    "test -f \"{{prefix}}/lib/pkgconfig/popt.pc\"",
  ]
}

provenance {
  read = [
    "configure.ac",  # :2 version; :34 ld-version-script; :55-57 gettext; :70 the generated files
    "Makefile.am",   # the install rules
    "configure",     # :1472 --enable-static; :1481 --disable-nls
    "http://ftp.rpm.org/popt/releases/popt-1.x/", # the release listing
    "https://github.com/rpm-software-management/popt/releases", # the tag list
  ]

  consulted = []

  note = <<EOT
⚠ UNSIGNED. The release directory holds no .asc or .sig for popt-1.19.tar.gz
(http://ftp.rpm.org/popt/releases/popt-1.x/popt-1.19.tar.gz.asc answers 404),
and the GitHub release carries only the two tag archives. There is therefore
no signature to justify the digest; what stands in its place is a
cross-check made when the digest was recorded:

  - the release tarball (HTTP, sha256 c25a4838…40f9) was unpacked beside the
    GitHub tag archive of popt-1.19-release (HTTPS, sha256 6eb40d65…0060);
  - `diff -rq` of the two trees shows ONLY files that autotools generates
    (configure, Makefile.in, aclocal.m4, config.h.in, build-aux/, m4/,
    ABOUT-NLS, the .gmo catalogues and po/ helper scripts) and two files the
    archive carries for git (.gitignore, .popt). Every hand-written source is
    byte-identical.

That is evidence the release tarball's sources are the tag's sources; it is
NOT evidence about the generated files, which the cross-check cannot cover.

The licence was NOT re-read from COPYING in this session: MIT is stated from
the project's long-standing licence.

⛔ NOT BUILT. Unverified: that the shipped configure accepts exactly the
`--disable-nls` and `--disable-static` spellings above (read at
configure:1472 and :1481).
EOT
}
