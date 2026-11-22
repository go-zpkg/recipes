# gnutls.org — GnuTLS, the TLS/DTLS library and certtool/gnutls-cli tools.
# Step 2 of go-zpkg/recipes#348 (design go-zpkg/packages#440): libtasn1 ->
# p11-kit -> gnutls; systemd's gnutls and p11kit options follow in a second
# commit.
#
# ⛔ WRITTEN FROM GNUTLS'S OWN FILES (configure.ac, m4/hooks.m4), at 3.8.14,
# the newest release (gitlab.com/gnutls/gnutls tags; gnupg.org's mirror lists
# it under gcrypt/gnutls/v3.8/).
# ⛔ NOT BUILT. Builds are suspended by a security hold; what is established
# is the inputs, each traced to a line in gnutls's own files.

summary = "GnuTLS: TLS, DTLS and X.509 library with command line tools"

# The library is LGPL-2.1-or-later; the tools and tests are GPL-3.0-or-later.
# NOT re-read from COPYING in this authoring session: stated from the
# project's long-standing licensing and flagged in provenance.note.
license = "LGPL-2.1-or-later AND GPL-3.0-or-later"

versions {
  url   = "https://www.gnupg.org/ftp/gcrypt/gnutls/v3.8/"
  match = "/gnutls-3\\.8\\.\\d+\\.tar\\.xz/"
  strip = ["/gnutls-/", "/\\.tar\\.xz/"]
}

dependencies = {
  "gnu.org/nettle"       = "*"
  "gnu.org/gmp"          = "*"
  "gnu.org/libtasn1"     = "4"
  "gnu.org/libidn2"      = "*"
  "github.com/p11-glue/p11-kit" = "0"
  "zlib.net"             = "1"
  "facebook.com/zstd"    = "1"
}

distributable {
  # The SIGNED release tarball from gnupg.org's mirror of the gnutls
  # release directory; the .sig sits beside it.
  url              = "https://www.gnupg.org/ftp/gcrypt/gnutls/v3.8/gnutls-{{version.raw}}.tar.xz"
  strip-components = 1

  # 3.8.14: 7375044 bytes. `zpkb sourcepin --sig auto` verified the detached
  # signature (see provenance.note); an independent `shasum -a 256` gave the
  # same digest.
  sha256 = {
    "3.8.14" = "7e2d258071f5db9620aa7ff34259331d004f7beafa3eb18560cfaf60acfbf02a"
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

      # configure.ac:112 — "don't generate any documentation".
      "--disable-doc",

      # configure.ac:395-397: the self tests default to following --enable-tools
      # and run a large network-free suite; none is installed. OFF.
      "--disable-tests",

      # configure.ac:147 — the C++ bindings (libgnutlsxx); nothing here uses
      # them. OFF.
      "--disable-cxx",

      # configure.ac:857 — libdane needs libunbound, which has no recipe here
      # and no declared link path. OFF.
      "--disable-libdane",

      # configure.ac:981 and :1063 — TPM2 and TPM 1.2 support. tpm2-tss has no
      # recipe here, and TPM 1.2's trousers is long obsolete. Both OFF.
      "--without-tpm2",
      "--without-tpm",

      # configure.ac:1174 — brotli compression; no brotli recipe exists. OFF.
      "--without-brotli",

      # configure.ac:1120-1126: `yes` becomes dlopen when the dlopen check
      # passes and link otherwise — a build-dependent choice. `link` pins it,
      # so zlib and zstd (configure.ac:1242) are on the library's own
      # NEEDED line, where the dependency closure sees them.
      "--with-zlib=link",
      "--with-zstd=link",

      # configure.ac:514 — without this, a libunistring found on the builder
      # is a hard error; the bundled copy keeps gnutls self-contained, the
      # same choice the gnu.org/libidn2 recipe makes.
      "--with-included-unistring",

      # configure.ac:930-934 `--with-p11-kit` — a missing p11-kit >= 0.23.1 is
      # an error (:944), not a silent no. Named explicitly.
      "--with-p11-kit",

      # configure.ac:1356-1372: left alone, the default trust store FILE is
      # whichever of five distribution paths exists on the BUILD host — a host
      # dependence. Pinned to the Debian/Ubuntu bundle path, which is a RUNTIME
      # location (nothing is read at build time).
      "--with-default-trust-store-file=/etc/ssl/certs/ca-certificates.crt",
    ]

    # m4/hooks.m4:72-102: nettle, hogweed and libtasn1 are probed by pkg-config
    # (minimums NETTLE_MINIMUM and LIBTASN1_MINIMUM); gmp by AC_CHECK_LIB
    # (:92) — hence the link flags below. p11-kit-1 is configure.ac:934.
    PKG_CONFIG_PATH = "{{deps.gnu.org/nettle.prefix}}/lib/pkgconfig:{{deps.gnu.org/nettle.prefix}}/lib64/pkgconfig:{{deps.gnu.org/libtasn1.prefix}}/lib/pkgconfig:{{deps.github.com/p11-glue/p11-kit.prefix}}/lib/pkgconfig:{{deps.gnu.org/libidn2.prefix}}/lib/pkgconfig:{{deps.zlib.net.prefix}}/lib/pkgconfig:{{deps.facebook.com/zstd.prefix}}/lib/pkgconfig"
    CPPFLAGS        = "-I{{deps.gnu.org/gmp.prefix}}/include"
    LDFLAGS         = "-L{{deps.gnu.org/gmp.prefix}}/lib -Wl,-rpath,{{prefix}}/lib -Wl,-rpath,{{deps.gnu.org/gmp.prefix}}/lib -Wl,-rpath,{{deps.gnu.org/nettle.prefix}}/lib -Wl,-rpath,{{deps.gnu.org/nettle.prefix}}/lib64 -Wl,-rpath,{{deps.gnu.org/libtasn1.prefix}}/lib -Wl,-rpath,{{deps.github.com/p11-glue/p11-kit.prefix}}/lib -Wl,-rpath,{{deps.gnu.org/libidn2.prefix}}/lib -Wl,-rpath,{{deps.zlib.net.prefix}}/lib -Wl,-rpath,{{deps.facebook.com/zstd.prefix}}/lib"
  }

  script = [
    "./configure $ARGS",
    "make --jobs {{ hw.concurrency }}",
    "make install",
  ]
}

# src/Makefile.am:57 `bin_PROGRAMS = psktool gnutls-cli-debug certtool
# gnutls-serv gnutls-cli`; :59 srptool, :63 ocsptool, :77 p11tool (conditional
# on features left at their default ON here). danetool (:67) and tpmtool (:74)
# are conditional on the libdane and TPM options turned OFF above.
provides = [
  "bin/certtool",
  "bin/gnutls-cli",
  "bin/gnutls-serv",
  "bin/p11tool",
]

test {
  script = [
    "test -x \"{{prefix}}/bin/certtool\"",
    "test -x \"{{prefix}}/bin/gnutls-cli\"",
    "test -x \"{{prefix}}/bin/p11tool\"",
    "test -f \"{{prefix}}/include/gnutls/gnutls.h\"",
    "test -f \"{{prefix}}/lib/pkgconfig/gnutls.pc\"",
    # configure.ac:937-940: with p11-kit on, gnutls.pc carries it in
    # Requires.private — read off the artifact.
    "grep -q p11-kit-1 \"{{prefix}}/lib/pkgconfig/gnutls.pc\"",
    "\"{{prefix}}/bin/gnutls-cli\" --version >/dev/null",
  ]
}

provenance {
  read = [
    "configure.ac",    # :112 --disable-doc; :147 cxx; :395 tests; :514 unistring; :857 libdane; :930-953 p11-kit; :981 tpm2; :1063 tpm; :1120-1126 zlib; :1174 brotli; :1242 zstd; :1332-1372 default trust store
    "m4/hooks.m4",     # :72-102 nettle, hogweed, gmp and libtasn1 detection
    "src/Makefile.am", # :57-77 the installed tools
    "https://gnutls.org/download.html", # :76 the release keyring
    "https://www.gnupg.org/ftp/gcrypt/gnutls/v3.8/", # the release listing
  ]

  consulted = []

  note = <<EOT
  signature  https://www.gnupg.org/ftp/gcrypt/gnutls/v3.8/gnutls-3.8.14.tar.xz.sig
  signer     subkey A6AB53A01D237A94F9EEC4D0412748A40AFCC2FB, signed 2026-11-18
  primary    E987AB7F7E89667776D05B3BB0E9DD20B29F1432
  identity   Alexander Sosedkin
  key from   https://gnutls.org/gnutls-release-keyring.gpg, which
             https://gnutls.org/download.html names as the release keyring

The keyring and the download page are on gnutls.org and the tarball on
gnupg.org's mirror of the same release directory: the warrant is the project's
own key list — continuity with the project, not independence. No keyserver was
asked.

Left OFF, each for a missing recipe or a missing link path: libdane (unbound),
TPM2 and TPM 1.2, brotli. The C++ bindings and the self tests are OFF too.

⛔ NOT BUILT. Unverified: the licence line (stated, COPYING not re-read);
that nettle's recipe installs pkg-config files under lib rather than lib64
(both are on the search path); that the bundled libunistring option spelling
`--with-included-unistring` is accepted at 3.8.14 (read at configure.ac:514).
EOT
}
