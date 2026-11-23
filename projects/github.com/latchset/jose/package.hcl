# github.com/latchset/jose — C implementation of JSON Object Signing and
# Encryption (RFC 7515 JWS, 7516 JWE, 7517 JWK, 7518 JWA): libjose and the
# `jose` command (jose jwk gen, jose jws sig, jose jwe enc, ...).
#
# It is here for clevis, which shells out to `jose` for every key and every
# JWE it makes (clevis-encrypt-*, clevis-decrypt-*).
#
# ⛔ WRITTEN FROM JOSE'S OWN FILES (meson.build, meson_options.txt) at v15, the
# newest release (GitHub `releases/latest`). The release tarball is used (.tar.xz).
# The digest is computed from my own download.
#
# WHAT IS BUILT. meson.build needs jansson, libcrypto (openssl) and zlib through
# pkg-config. `-Ddocs=disabled` turns the man pages off (they need asciidoc,
# which has no recipe here; the option is a meson feature). The default
# `werror=true` is kept: it built clean with gcc 14.

summary = "jose: C library and command for JSON Web Signature, Encryption and Keys (RFC 7515-7518)"

license = "Apache-2.0"

platforms = ["linux"]

versions {
  # Tags are `v15`.
  github = "latchset/jose"
}

dependencies = {
  "github.com/akheron/jansson" = "2"
  "openssl.org"                = "^3"
  "zlib.net"                   = "*"
}

distributable {
  url              = "https://github.com/latchset/jose/releases/download/v{{version.raw}}/jose-{{version.raw}}.tar.xz"
  strip-components = 1

  # 15, computed from my own download.
  sha256 = {
    "15" = "1d055c445392aa48d709ecd6e56220384ae2b480496e270818bddf1f219c8659"
  }
}

build {
  dependencies = {
    "mesonbuild.com"             = "*"
    "ninja-build.org"            = "*"
    "freedesktop.org/pkg-config" = "*"
    "gnu.org/gcc"                = "*"
  }

  env = {
    ARGS = [
      "--prefix={{prefix}}",
      "--libdir=lib",
      "--buildtype=release",
      "-Ddocs=disabled",
    ]

    PKG_CONFIG_PATH = "{{deps.github.com/akheron/jansson.prefix}}/lib/pkgconfig:{{deps.openssl.org.prefix}}/lib/pkgconfig:{{deps.openssl.org.prefix}}/lib64/pkgconfig:{{deps.zlib.net.prefix}}/lib/pkgconfig"

    LDFLAGS = "-Wl,-rpath,{{prefix}}/lib -Wl,-rpath,{{deps.github.com/akheron/jansson.prefix}}/lib -Wl,-rpath,{{deps.openssl.org.prefix}}/lib -Wl,-rpath,{{deps.openssl.org.prefix}}/lib64 -Wl,-rpath,{{deps.zlib.net.prefix}}/lib"
  }

  script = [
    "meson setup build $ARGS",
    "meson compile -C build",
    "meson install -C build",
  ]
}

provides = [
  "bin/jose",
]

test {
  script = [
    "test -x {{prefix}}/bin/jose",
    # Keys: generate an EC key, derive its public half.
    "jose jwk gen -i '{\"alg\":\"ES256\"}' -o ec.jwk",
    "jose jwk pub -i ec.jwk -o ec.pub",
    "grep -q '\"crv\":\"P-256\"' ec.pub",
    # Sign and verify.
    "printf hello > msg",
    "jose jws sig -I msg -k ec.jwk -o sig.jws",
    "jose jws ver -i sig.jws -k ec.pub -O out.msg",
    "cmp msg out.msg",
    # A different key must be refused.
    "jose jwk gen -i '{\"alg\":\"ES256\"}' -o other.jwk",
    "jose jwk pub -i other.jwk -o other.pub",
    "if jose jws ver -i sig.jws -k other.pub > /dev/null 2>&1; then exit 1; fi",
    # Encrypt and decrypt.
    "jose jwk gen -i '{\"alg\":\"A256GCM\"}' -o sym.jwk",
    "jose jwe enc -I msg -k sym.jwk -o msg.jwe",
    "jose jwe dec -i msg.jwe -k sym.jwk -O dec.msg",
    "cmp msg dec.msg",
  ]
}

provenance {
  read = [
    "meson.build",
    "meson_options.txt",
    "https://github.com/latchset/jose/releases",
  ]

  consulted = []

  note = <<EOT
Built and run on Linux (aarch64, glibc) with the commands of this file, against
the container's jansson, openssl and zlib; every test line passed there. Not
built against the pantry's own jansson recipe (it is written beside this one).

⚠ The man pages are off (-Ddocs=disabled): asciidoc has no recipe.
EOT
}
