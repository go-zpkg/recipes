# gnu.org/libmicrohttpd — GNU libmicrohttpd, an embeddable HTTP server library.
# Batch 3 of go-zpkg/recipes#348 (design go-zpkg/packages#440): systemd's
# `microhttpd` option (meson_options.txt:444) is what systemd-journal-remote
# serves its HTTP endpoint with.
#
# ⛔ WRITTEN FROM libmicrohttpd's configure.ac at 1.0.11. NOT BUILT: builds are
# suspended by a security hold; what is established is the inputs.
#
# HTTPS is ON, through GnuTLS (gnutls.org recipe, go-zpkg/recipes#350):
#   --enable-https (configure.ac:3593-3597, default `auto`) and
#   --with-gnutls=yes (:3616-3618, "automatically, forced"): GnuTLS is then
#   found by pkg-config (:3650), and a missing or unusable one is a hard error
#   (:3740-3741) instead of a silent fall back to libgcrypt (:3707) or to a
#   plain-HTTP build. systemd-journal-remote and journal-gatewayd can then
#   serve TLS.
#
# WHAT IS OFF, with the reason:
#   Nothing of HTTPS: it is ON (below).
#   --disable-doc, --disable-examples, --disable-tools (:2215-2231): defaults ON;
#       the examples and tools need libcurl and are not installed products.
#   --disable-curl (:3277): `curl` only enables test programs that link libcurl.

summary = "GNU libmicrohttpd: embeddable HTTP server library (HTTP and HTTPS)"

license = "LGPL-2.1-or-later"

platforms = ["linux"]

versions {
  url   = "https://ftp.gnu.org/gnu/libmicrohttpd/"
  match = "/libmicrohttpd-\\d+\\.\\d+\\.\\d+\\.tar\\.gz/"
  strip = ["/libmicrohttpd-/", "/\\.tar\\.gz/"]
}

distributable {
  # The SIGNED release tarball (.sig beside it), generated configure included.
  url              = "https://ftp.gnu.org/gnu/libmicrohttpd/libmicrohttpd-{{version.raw}}.tar.gz"
  strip-components = 1

  sha256 = {
    "1.0.11" = "f227a044b75688e449b58ddedf0582255cc562899ff69f173a8ef76439744b4e"
  }
}

dependencies = {
  "gnutls.org" = "3"
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
      "--enable-https",
      "--with-gnutls=yes",
      "--disable-doc",
      "--disable-examples",
      "--disable-tools",
      "--disable-curl",
      "--disable-static",
    ]
    PKG_CONFIG_PATH = "{{deps.gnutls.org.prefix}}/lib/pkgconfig"
    LDFLAGS         = "-Wl,-rpath,{{prefix}}/lib -Wl,-rpath,{{deps.gnutls.org.prefix}}/lib"
  }

  script = [
    "./configure $ARGS",
    "make --jobs {{ hw.concurrency }}",
    "make install",
  ]
}

test {
  script = [
    "test -f \"{{prefix}}/include/microhttpd.h\"",
    "test -f \"{{prefix}}/lib/pkgconfig/libmicrohttpd.pc\"",
    "grep -q '^Version: {{version.raw}}' \"{{prefix}}/lib/pkgconfig/libmicrohttpd.pc\"",
    "test -e \"{{prefix}}/lib/libmicrohttpd.so\"",  ]
}

provenance {
  read = [
    "configure.ac",  # :2215-2231 doc, examples, tools; :3277 curl; :3593-3705 https and gnutls; :3707 gcrypt
    "https://ftp.gnu.org/gnu/libmicrohttpd/ (the release listing)",
  ]

  consulted = []

  note = <<EOT
  signature  https://ftp.gnu.org/gnu/libmicrohttpd/libmicrohttpd-1.0.11.tar.gz.sig
  signer     D8423BCB326C7907033929C7939E6BE1E29FC3CC, signed 2026-11-19
  identity   Christian Grothoff
  key from   keyserver.ubuntu.com, verified by `zpkb sourcepin --sig auto`.

⚠ THE FINGERPRINT IS NOT NAMED BY THE PROJECT. The signature's own issuer
fingerprint was used; trust rests on the key carrying the maintainer's user ID
as the keyserver holds it.

⛔ NOT BUILT. Unverified: that the built library names GnuTLS (no test line
asserts it: what the .pc or the NEEDED line carries was not read off an
artifact); that each --disable-* spelling is accepted verbatim
(read from configure.ac AC_ARG_ENABLE names, not run); that the `versions`
regex resolves against the listing (copied from the libidn2 recipe's form).
EOT
}
