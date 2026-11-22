# gnu.org/libtasn1 — the ASN.1 / DER library gnutls and p11-kit parse
# certificates and PKCS#11 module data with. Step 2 of go-zpkg/recipes#348
# (design go-zpkg/packages#440): libtasn1 -> p11-kit -> gnutls.
#
# ⛔ WRITTEN FROM LIBTASN1'S OWN FILES, at 4.21.0 (its newest release: the
# project's tag list on gitlab.com/gnutls/libtasn1 ends at v4.21.0).
# ⛔ NOT BUILT. Builds are suspended by a security hold; what is established
# is the inputs, each traced to a line in libtasn1's own files.

summary = "GNU Libtasn1: ASN.1 structure parser and DER encoder/decoder"

# README.md:7-17 — three licences in one package:
#   - the C library (lib/): LGPL version 2.1 or later;
#   - the command line tools (src/), tests and examples: GPL version 3 or later;
#   - the manual (doc/): GNU Free Documentation License 1.3 or later.
license = "LGPL-2.1-or-later AND GPL-3.0-or-later AND GFDL-1.3-or-later"

versions {
  url   = "https://ftp.gnu.org/gnu/libtasn1/"
  match = "/libtasn1-\\d+\\.\\d+(\\.\\d+)?\\.tar\\.gz/"
  strip = ["/libtasn1-/", "/\\.tar\\.gz/"]
}

distributable {
  url              = "https://ftp.gnu.org/gnu/libtasn1/libtasn1-{{version.raw}}.tar.gz"
  strip-components = 1

  # 4.21.0: 1816537 bytes. Recorded with `zpkb sourcepin --sig auto`
  # (signature verified, see provenance.note) and confirmed by an independent
  # `shasum -a 256` of the same file. ftp.gnu.org did not answer from the
  # authoring host, so the bytes were fetched from mirrors.kernel.org/gnu/,
  # which carries the same path; the digest is of the file, not of the host.
  sha256 = {
    "4.21.0" = "1d8a444a223cc5464240777346e125de51d8e6abf0b8bac742ac84609167dc87"
  }
}

build {
  dependencies = {
    "gnu.org/make" = "*"
  }

  env = {
    ARGS = [
      "--prefix={{prefix}}",

      # configure.ac:50-53 — "don't generate any documentation". Generating it
      # needs gtk-doc (configure.ac:59 GTK_DOC_CHECK) and help2man
      # (configure.ac:57), neither declared here.
      "--disable-doc",

      # configure.ac:104-107 — fuzzing build, default off; stated.
      "--disable-fuzzing",
    ]
  }

  script = [
    "./configure $ARGS",
    "make --jobs {{ hw.concurrency }}",
    "make install",
  ]
}

# src/Makefile.am:28 `bin_PROGRAMS = asn1Parser asn1Coding asn1Decoding`;
# lib/Makefile.am:31 `lib_LTLIBRARIES = libtasn1.la`, :26 the header,
# :29 `pkgconfig_DATA = libtasn1.pc`.
provides = [
  "bin/asn1Parser",
  "bin/asn1Coding",
  "bin/asn1Decoding",
]

test {
  script = [
    "test -f \"{{prefix}}/include/libtasn1.h\"",
    "test -f \"{{prefix}}/lib/pkgconfig/libtasn1.pc\"",
    "test -x \"{{prefix}}/bin/asn1Parser\"",
    "test -x \"{{prefix}}/bin/asn1Coding\"",
    "test -x \"{{prefix}}/bin/asn1Decoding\"",
  ]
}

provenance {
  read = [
    "README.md",          # :7-17 the three licences
    "configure.ac",       # :19-34 version; :50-53 --disable-doc; :57-59 help2man and gtk-doc; :104-107 --enable-fuzzing
    "lib/Makefile.am",    # :26 libtasn1.h; :29 the .pc file; :31 the library
    "src/Makefile.am",    # :28 the three tools
    "https://ftp.gnu.org/gnu/libtasn1/", # the release listing
  ]

  consulted = [
    "https://gitlab.com/gnutls/libtasn1/-/tags", # newest release is v4.21.0
  ]

  note = <<EOT
  signature  https://ftp.gnu.org/gnu/libtasn1/libtasn1-4.21.0.tar.gz.sig
             (read from the same path on mirrors.kernel.org/gnu/)
  signer     subkey 51722B08FE4745A2 (Ed25519), signed 2026-01-08T13:41:36Z
  primary    B1D2BD1375BECB784CF4F8C4D73CF638C53C06BE
  identity   Simon Josefsson <simon@josefsson.org>
  key from   https://ftp.gnu.org/gnu/gnu-keyring.gpg (read from mirrors.kernel.org/gnu/)
  judged at  2026-04-17T08:55:45Z, the key's newest self-signature
             (go-zpkg/zpkb#512)

The signer's fingerprint was read from the signature's own issuer field and
found in GNU's maintainer keyring: the warrant is GNU's curation of that
keyring, on the same host as the tarball — continuity, not independence. It is
the same primary the gnu.org/libidn2 recipe records. No keyserver was asked.

⛔ NOT BUILT. Unverified: that libtasn1.h lands in include/ with the default
layout, and that the tarball needs no yacc (it ships the generated parser).
EOT
}
